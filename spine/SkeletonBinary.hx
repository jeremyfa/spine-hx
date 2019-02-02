package spine;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Path;
import spine.PathConstraintData.PositionMode;
import spine.PathConstraintData.SpacingMode;
import spine.SkeletonJson.LinkedMesh;
import spine.Animation;
import spine.Animation.ColorTimeline;
import spine.Animation.CurveTimeline;
import spine.Animation.DeformTimeline;
import spine.Animation.DrawOrderTimeline;
import spine.Animation.EventTimeline;
import spine.Animation.IkConstraintTimeline;
import spine.Animation.PathConstraintMixTimeline;
import spine.Animation.PathConstraintPositionTimeline;
import spine.Animation.PathConstraintSpacingTimeline;
import spine.Animation.RotateTimeline;
import spine.Animation.ScaleTimeline;
import spine.Animation.ShearTimeline;
import spine.Animation.Timeline;
import spine.Animation.TransformConstraintTimeline;
import spine.Animation.TranslateTimeline;
import spine.Animation.TwoColorTimeline;
import spine.attachments.Attachment;
import spine.attachments.AttachmentLoader;
import spine.attachments.AttachmentType;
import spine.attachments.BoundingBoxAttachment;
import spine.attachments.ClippingAttachment;
import spine.attachments.MeshAttachment;
import spine.attachments.PathAttachment;
import spine.attachments.PointAttachment;
import spine.attachments.RegionAttachment;
import spine.attachments.VertexAttachment;
import spine.support.graphics.Color;

#if !(js || flash)
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
#end

/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
 
/**
 * Binary data loader.
 * Should work with any Haxe framework.
 */
class SkeletonBinary 
{
	public static inline var BONE_ROTATE:Int = 0;
	public static inline var BONE_TRANSLATE:Int = 1;
	public static inline var BONE_SCALE:Int = 2;
	public static inline var BONE_SHEAR:Int = 3;

	public static inline var SLOT_ATTACHMENT:Int = 0;
	public static inline var SLOT_COLOR:Int = 1;
	public static inline var SLOT_TWO_COLOR:Int = 2;

	public static inline var PATH_POSITION:Int = 0;
	public static inline var PATH_SPACING:Int = 1;
	public static inline var PATH_MIX:Int = 2;

	public static inline var CURVE_LINEAR:Int = 0;
	public static inline var CURVE_STEPPED:Int = 1;
	public static inline var CURVE_BEZIER:Int = 2;
	
	/**
	 * Helper Bytes for reading float values from data
	 */
	private var floatBuffer:Bytes;
	/**
	 * Helper object for reading color values
	 */
	private var rgba:RGBA;
	
	/**
	 * Helper object for loading strings from bytes
	 */
	private var buffer:Bytes;
	
	private var attachmentLoader:AttachmentLoader;
	private var scale:Float = 1;
	private var linkedMeshes:Array<LinkedMesh> = new Array<LinkedMesh>();
	
	public function new(attachmentLoader:AttachmentLoader) 
	{
		floatBuffer = Bytes.alloc(4);
		rgba = new RGBA();
		buffer = Bytes.alloc(32);

		if (attachmentLoader == null) 
		{
			throw "attachmentLoader cannot be null.";
		}
		
		this.attachmentLoader = attachmentLoader;
	}
	
	/**
	 * Reads skeleton data from file, which can be found at specified path
	 * @param	path	file path
	 * @param	name	optional name for skeleton data. If it is ommited then filename will be used.
	 * @return	SkeletonData object.
	 */
	public function readSkeletonDataFromPath(path:String, ?name:String):SkeletonData 
	{
		#if !(js || flash)
		if (!FileSystem.exists(path))
		{
			throw ("There is no file: " + path);
			return null;
		}
		
		var input:FileInput = File.read(path, true);
		var skeletonData:SkeletonData = readSkeletonDataFromInput(input);
		input.close();
		
		if (name != null)
		{
			skeletonData.name = name;
		}
		else
		{
			skeletonData.name = Path.withoutExtension(path);
		}
		
		return skeletonData;
		#else 
		throw "Can't read from file on the web!";
		return null;
		#end
	}
	
	/**
	 * Reads skeleton data from specified Bytes object.
	 * 
	 * @param	bytes	bytes to read data from
	 * @param	name	skeleton data name
	 * @param	start	optional start position in binary data just in case if you want to pack multiple skeleton datas in one big blob).
	 * @return	SkeletonData object.
	 */
	public function readSkeletonDataFromBytes(bytes:Bytes, name:String, start:Int = 0):SkeletonData 
	{
		if (bytes == null)
		{
			throw "Empty byte data!";
			return null;
		}
		
		var input:BytesInput = new BytesInput(bytes);
		input.position = start;
		var skeletonData:SkeletonData = readSkeletonDataFromInput(input);
		input.close();
		skeletonData.name = name;
		return skeletonData;
	}
	
	/**
	 * Reads skeleton data from specified `Input` object
	 * 
	 * @param	input	input source to read data from
	 * @return	Skeleton Data object.
	 */
	public function readSkeletonDataFromInput(input:Input):SkeletonData 
	{
		if (input == null) 
		{
			throw "Null input!";
			return null;
		}
		
		var scale:Float = this.scale;
		
		var skeletonData = new SkeletonData();
		skeletonData.hash = ReadString(input);
		if (skeletonData.hash.length == 0) 
		{
			skeletonData.hash = null;
		}
		
		skeletonData.version = ReadString(input);
		if (skeletonData.version.length == 0) 
		{
			skeletonData.version = null;
		}

		skeletonData.width = ReadFloat(input);
		skeletonData.height = ReadFloat(input);

		var nonessential:Bool = ReadBoolean(input);
		if (nonessential) 
		{
			skeletonData.fps = ReadFloat(input);
			skeletonData.imagesPath = ReadString(input);
			if (IsNullOrEmpty(skeletonData.imagesPath)) 
			{
				skeletonData.imagesPath = null;
			}

			skeletonData.audioPath = ReadString(input);
			if (IsNullOrEmpty(skeletonData.audioPath)) 
			{
				skeletonData.audioPath = null;
			}
		}

		// Bones.
		var n:Int = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var name:String = ReadString(input);
			var parent:BoneData = (i == 0) ? null : skeletonData.bones[ReadVarint(input, true)];
			var data:BoneData = new BoneData(i, name, parent);
			data.rotation = ReadFloat(input);		
			data.x = ReadFloat(input) * scale;
			data.y = ReadFloat(input) * scale;
			data.scaleX = ReadFloat(input);
			data.scaleY = ReadFloat(input);
			data.shearX = ReadFloat(input);
			data.shearY = ReadFloat(input);
			data.length = ReadFloat(input) * scale;
			data.transformMode = ReadVarint(input, true);
			
			if (nonessential) 
			{
				ReadInt(input); // Skip bone color.
			}
			
			skeletonData.bones.push(data);
		}

		// Slots.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var slotName:String = ReadString(input);
			var boneData:BoneData = skeletonData.bones[ReadVarint(input, true)];
			var slotData:SlotData = new SlotData(i, slotName, boneData);
			var color:RGBA = ReadInt(input);
			slotData.color.set(color.floatX, color.floatY, color.floatZ, color.floatW);
			
			var darkColor:RGBA = ReadInt(input); // 0x00rrggbb
			var darkInt:Int = (darkColor.x << 24) + (darkColor.y << 16) + (darkColor.z << 8) + darkColor.w;
			if (darkInt != -1) 
			{
			//	slotData.hasSecondColor = true;
				slotData.setDarkColor(new Color(darkColor.floatY, darkColor.floatZ, darkColor.floatW, 1.0));
			}
			
			slotData.attachmentName = ReadString(input);
			slotData.blendMode = ReadVarint(input, true);
			skeletonData.slots.push(slotData);
		}

		// IK constraints.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:IkConstraintData = new IkConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			data.target = skeletonData.bones[ReadVarint(input, true)];
			data.mix = ReadFloat(input);
			data.bendDirection = ReadSByte(input);
			data.compress = ReadBoolean(input);
			data.stretch = ReadBoolean(input);
			data.uniform = ReadBoolean(input);
			skeletonData.ikConstraints.push(data);
		}

		// Transform constraints.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:TransformConstraintData = new TransformConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			data.target = skeletonData.bones[ReadVarint(input, true)];
			data.local = ReadBoolean(input);
			data.relative = ReadBoolean(input);
			data.offsetRotation = ReadFloat(input);
			data.offsetX = ReadFloat(input) * scale;
			data.offsetY = ReadFloat(input) * scale;
			data.offsetScaleX = ReadFloat(input);
			data.offsetScaleY = ReadFloat(input);
			data.offsetShearY = ReadFloat(input);
			data.rotateMix = ReadFloat(input);
			data.translateMix = ReadFloat(input);
			data.scaleMix = ReadFloat(input);
			data.shearMix = ReadFloat(input);
			skeletonData.transformConstraints.push(data);
		}

		// Path constraints
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:PathConstraintData = new PathConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			
			data.target = skeletonData.slots[ReadVarint(input, true)];
			data.positionMode = ReadVarint(input, true);	
			data.spacingMode = ReadVarint(input, true);
			data.rotateMode = ReadVarint(input, true);
			data.offsetRotation = ReadFloat(input);
			data.position = ReadFloat(input);
			
			if (data.positionMode == PositionMode.fixed) 
			{
				data.position *= scale;
			}
			
			data.spacing = ReadFloat(input);
			if (data.spacingMode == SpacingMode.length || data.spacingMode == SpacingMode.fixed) 
			{
				data.spacing *= scale;
			}
			
			data.rotateMix = ReadFloat(input);
			data.translateMix = ReadFloat(input);
			skeletonData.pathConstraints.push(data);
		}

		// Default skin.
		var defaultSkin:Skin = ReadSkin(input, skeletonData, "default", nonessential);
		if (defaultSkin != null) 
		{
			skeletonData.defaultSkin = defaultSkin;
			skeletonData.skins.push(defaultSkin);
		}

		// Skins.
		n = ReadVarint(input, true);
		for (i in 0...n)
		{
			skeletonData.skins.push(ReadSkin(input, skeletonData, ReadString(input), nonessential));
		}

		// Linked meshes.
		for (i in 0...linkedMeshes.length) 
		{
			var linkedMesh:LinkedMesh = linkedMeshes[i];
			var skin:Skin = (linkedMesh.skin == null) ? skeletonData.defaultSkin : skeletonData.findSkin(linkedMesh.skin);
			if (skin == null) 
			{
				throw ("Skin not found: " + linkedMesh.skin);
			}
			
			var parent:Attachment = skin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
			if (parent == null) 
			{
				throw ("Parent mesh not found: " + linkedMesh.parent);
			}
			
			linkedMesh.mesh.setParentMesh(cast parent);
			linkedMesh.mesh.updateUVs();
		}
		linkedMeshes = [];

		// Events.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:EventData = new EventData(ReadString(input));
			data.intValue = ReadVarint(input, false);
			data.floatValue = ReadFloat(input);
			data.stringValue = ReadString(input);
			data.audioPath = ReadString(input);

			if (data.audioPath != null)
			{
				data.volume = ReadFloat(input);
				data.balance = ReadFloat(input);
			}

			skeletonData.events.push(data);
		}

		// Animations.
		n = ReadVarint(input, true);
		for (i in 0...n)
		{
			ReadAnimation(ReadString(input), input, skeletonData);
		}
		
		return skeletonData;
	}
	
	/// <returns>May be null.</returns>
	private function ReadSkin(input:Input, skeletonData:SkeletonData, skinName:String, nonessential:Bool):Skin
	{
		var slotCount:Int = ReadVarint(input, true);
		if (slotCount == 0) 
		{
			return null;
		}
		
		var skin:Skin = new Skin(skinName);
		for (i in 0...slotCount) 
		{
			var slotIndex:Int = ReadVarint(input, true);
			var nn:Int = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var name:String = ReadString(input);
				var attachment:Attachment = ReadAttachment(input, skeletonData, skin, slotIndex, name, nonessential);
				if (attachment != null) 
				{
					skin.addAttachment(slotIndex, name, attachment);
				}
			}
		}
		
		return skin;
	}
	
	private function ReadAttachment(input:Input, skeletonData:SkeletonData, skin:Skin, slotIndex:Int, attachmentName:String, nonessential:Bool):Attachment 
	{
		var scale:Float = this.scale;

		var name:String = ReadString(input);
		if (name == null) 
		{
			name = attachmentName;
		}
		
		var type:AttachmentType = input.readByte();
		switch (type) 
		{
			case AttachmentType.region:
				var path:String = ReadString(input);
				var rotation:Float = ReadFloat(input);
				var x:Float = ReadFloat(input);
				var y:Float = ReadFloat(input);
				var scaleX:Float = ReadFloat(input);
				var scaleY:Float = ReadFloat(input);
				var width:Float = ReadFloat(input);
				var height:Float = ReadFloat(input);
				var color:RGBA = ReadInt(input);

				if (path == null) 
				{
					path = name;
				}
				
				var region:RegionAttachment = attachmentLoader.newRegionAttachment(skin, name, path);
				if (region == null) 
				{
					return null;
				}
				
				region.setPath(path);
				region.setX(x * scale);
				region.setY(y * scale);
				region.setScaleX(scaleX);
				region.setScaleY(scaleY);
				region.setRotation(rotation);
				region.setWidth(width * scale);
				region.setHeight(height * scale);
				region.getColor().set(color.floatX, color.floatY, color.floatZ, color.floatW);
				region.updateOffset();
				return region;
			
			case AttachmentType.boundingbox:
				var vertexCount:Int = ReadVarint(input, true);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				if (nonessential) 
				{
					ReadInt(input); //int color = nonessential ? ReadInt(input) : 0; // Avoid unused local warning.
				}
				
				var box:BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
				if (box == null) 
				{
					return null;
				}
				
				box.worldVerticesLength = vertexCount << 1;
				box.vertices = vertices.vertices;
				box.bones = vertices.bones;      
				return box;
			
			case AttachmentType.mesh:
				var path:String = ReadString(input);
				var color:RGBA = ReadInt(input);
				var vertexCount:Int = ReadVarint(input, true);			
				var uvs:Array<Float> = ReadFloatArray(input, vertexCount << 1, 1);
				var triangles:Array<Int> = ReadShortArray(input);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				var hullLength:Int = ReadVarint(input, true);
				var edges:Array<Int> = null;
				var width:Float = 0;
				var height:Float = 0;
				if (nonessential) 
				{
					edges = ReadShortArray(input);
					width = ReadFloat(input);
					height = ReadFloat(input);
				}

				if (path == null) 
				{
					path = name;
				}
				
				var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
				if (mesh == null) 
				{
					return null;
				}
				
				mesh.setPath(path);
				mesh.getColor().set(color.floatX, color.floatY, color.floatZ, color.floatW);
				mesh.bones = vertices.bones;
				mesh.vertices = vertices.vertices;
				mesh.worldVerticesLength = vertexCount << 1;
				mesh.setTriangles(triangles);
				mesh.setRegionUVs(uvs);
				mesh.updateUVs();
				mesh.setHullLength(hullLength << 1);
				if (nonessential) 
				{
					mesh.setEdges(edges);
					mesh.setWidth(width * scale);
					mesh.setHeight(height * scale);
				}
				return mesh;
			
			case AttachmentType.linkedmesh:
				var path:String = ReadString(input);
				var color:RGBA = ReadInt(input);
				var skinName:String = ReadString(input);
				var parent:String = ReadString(input);
				var inheritDeform:Bool = ReadBoolean(input);
				var width:Float = 0;
				var height:Float = 0;
				if (nonessential) 
				{
					width = ReadFloat(input);
					height = ReadFloat(input);
				}

				if (path == null) 
				{
					path = name;
				}
				
				var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
				if (mesh == null) 
				{
					return null;
				}
				
				mesh.setPath(path);
				mesh.getColor().set(color.floatX, color.floatY, color.floatZ, color.floatW);
				mesh.setInheritDeform(inheritDeform);
				if (nonessential) 
				{
					mesh.setWidth(width * scale);
					mesh.setHeight(height * scale);
				}
				
				linkedMeshes.push(new LinkedMesh(mesh, skinName, slotIndex, parent));
				return mesh;
			
			case AttachmentType.path:
				var closed:Bool = ReadBoolean(input);
				var constantSpeed:Bool = ReadBoolean(input);
				var vertexCount:Int = ReadVarint(input, true);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				var n = Std.int(vertexCount / 3);
				var lengths:Array<Float> = []; // new float[vertexCount / 3];
				for (i in 0...n)
				{
					lengths[i] = ReadFloat(input) * scale;
				}
				if (nonessential) 
				{
					ReadInt(input); //int color = nonessential ? ReadInt(input) : 0;
				}

				var path:PathAttachment = attachmentLoader.newPathAttachment(skin, name);
				if (path == null) 
				{
					return null;
				}
				path.closed = closed;
				path.constantSpeed = constantSpeed;
				path.worldVerticesLength = vertexCount << 1;
				path.vertices = vertices.vertices;
				path.bones = vertices.bones;
				path.lengths = lengths;
				return path;
			
			case AttachmentType.point:
				var rotation:Float = ReadFloat(input);
				var x:Float = ReadFloat(input);
				var y:Float = ReadFloat(input);
				if (nonessential) 
				{
					ReadInt(input); //int color = nonessential ? ReadInt(input) : 0;
				}

				var point:PointAttachment = attachmentLoader.newPointAttachment(skin, name);
				if (point == null) 
				{
					return null;
				}
				
				point.x = x * scale;
				point.y = y * scale;
				point.rotation = rotation;
				//if (nonessential) point.color = color;
				return point;
			
			case AttachmentType.clipping: 
				var endSlotIndex:Int = ReadVarint(input, true);
				var vertexCount:Int = ReadVarint(input, true);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				if (nonessential) 
				{
					ReadInt(input);
				}

				var clip:ClippingAttachment = attachmentLoader.newClippingAttachment(skin, name);
				if (clip == null) 
				{
					return null;
				}
				clip.endSlot = skeletonData.slots[endSlotIndex];
				clip.worldVerticesLength = vertexCount << 1;
				clip.vertices = vertices.vertices;
				clip.bones = vertices.bones;
				return clip;
			
			default:
				
		}
		return null;
	}
	
	private function ReadVertices(input:Input, vertexCount:Int):Vertices
	{
		var scale:Float = this.scale;
		var verticesLength:Int = vertexCount << 1;
		var vertices:Vertices = new Vertices();
		
		if (!ReadBoolean(input)) 
		{
			vertices.vertices = ReadFloatArray(input, verticesLength, scale);
			return vertices;
		}
		
		var weights:Array<Float> = []; // new ExposedList<float>(verticesLength * 3 * 3);
		var bonesArray:Array<Int> = []; // new ExposedList<int>(verticesLength * 3);
		for (i in 0...vertexCount) 
		{
			var boneCount:Int = ReadVarint(input, true);
			bonesArray.push(boneCount);
			for (ii in 0...boneCount) 
			{
				bonesArray.push(ReadVarint(input, true));
				weights.push(ReadFloat(input) * scale);
				weights.push(ReadFloat(input) * scale);
				weights.push(ReadFloat(input));
			}
		}

		vertices.vertices = weights;
		vertices.bones = bonesArray;
		
		return vertices;
	}
	
	private function ReadFloatArray(input:Input, n:Int, scale:Float):Array<Float>
	{
		var array:Array<Float> = [for (i in 0...n) 0.0];
		if (scale == 1) 
		{
			for (i in 0...n)
			{
				array[i] = ReadFloat(input);
			}
		} 
		else 
		{
			for (i in 0...n)
			{
				array[i] = ReadFloat(input) * scale;
			}
		}

		return array;
	}
	
	private function ReadShortArray(input:Input):Array<Int> 
	{
		var n:Int = ReadVarint(input, true);
		var array:Array<Int> = [for (i in 0...n) 0]; // n is the length of this array
		for (i in 0...n) 
		{
			array[i] = (input.readByte() << 8) | input.readByte();
		}
		
		return array;
	}

	private function ReadAnimation(name:String, input:Input, skeletonData:SkeletonData):Void
	{
		var timelines:Array<Timeline> = [];
		var scale:Float = this.scale;
		var duration:Float = 0;

		// Slot timelines.
		var n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var slotIndex:Int = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte();
				var frameCount:Int = ReadVarint(input, true);
				
				switch (timelineType) 
				{
					case SLOT_ATTACHMENT:
						var timeline:AttachmentTimeline = new AttachmentTimeline(frameCount);
						timeline.slotIndex = slotIndex;
						for (frameIndex in 0...frameCount)
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadString(input));
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[frameCount - 1]);	
					
					case SLOT_COLOR:
						var timeline:ColorTimeline = new ColorTimeline(frameCount);
						timeline.slotIndex = slotIndex;
						for (frameIndex in 0...frameCount) 
						{
							var time:Float = ReadFloat(input);
							var color:RGBA = ReadInt(input);
							var r:Float = color.floatX;
							var g:Float = color.floatY;
							var b:Float = color.floatZ;
							var a:Float = color.floatW;
							timeline.setFrame(frameIndex, time, r, g, b, a);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * ColorTimeline.ENTRIES]);
					
					case SLOT_TWO_COLOR:
							var timeline:TwoColorTimeline = new TwoColorTimeline(frameCount);
							timeline.slotIndex = slotIndex;
							for (frameIndex in 0...frameCount) 
							{
								var time:Float = ReadFloat(input);
								var color:RGBA = ReadInt(input);
								var r:Float = color.floatX;
								var g:Float = color.floatY;
								var b:Float = color.floatZ;
								var a:Float = color.floatW;
								var color2:RGBA = ReadInt(input); // 0x00rrggbb
								var r2:Float = color2.floatY;
								var g2:Float = color2.floatZ;
								var b2:Float = color2.floatW;

								timeline.setFrame(frameIndex, time, r, g, b, a, r2, g2, b2);
								if (frameIndex < frameCount - 1) 
								{
									ReadCurve(input, frameIndex, timeline);
								}
							}
							timelines.push(timeline);
							duration = Math.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * TwoColorTimeline.ENTRIES]);
					
					default:
						
				}
			}
		}

		// Bone timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var boneIndex:Int = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte();
				var frameCount:Int = ReadVarint(input, true);
				switch (timelineType) 
				{
					case BONE_ROTATE:
						var timeline:RotateTimeline = new RotateTimeline(frameCount);
						timeline.boneIndex = boneIndex;
						for (frameIndex in 0...frameCount) 
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input));
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * RotateTimeline.ENTRIES]);
					
					case BONE_TRANSLATE | BONE_SCALE | BONE_SHEAR:
						
						var timeline:TranslateTimeline = null;
						var timelineScale:Float = 1;
						if (timelineType == BONE_SCALE)
						{
							timeline = new ScaleTimeline(frameCount);
						}
						else if (timelineType == BONE_SHEAR)
						{
							timeline = new ShearTimeline(frameCount);
						}
						else 
						{
							timeline = new TranslateTimeline(frameCount);
							timelineScale = scale;
						}
						timeline.boneIndex = boneIndex;
						for (frameIndex in 0...frameCount) 
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input) * timelineScale, ReadFloat(input) * timelineScale);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * TranslateTimeline.ENTRIES]);
					
					default:
						
				}
			}
		}

		// IK timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{				
			var index:Int = ReadVarint(input, true);
			var frameCount:Int = ReadVarint(input, true);
			var timeline:IkConstraintTimeline = new IkConstraintTimeline(frameCount);
			timeline.ikConstraintIndex = index;
			for (frameIndex in 0...frameCount) 
			{
				timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadSByte(input), ReadBoolean(input), ReadBoolean(input));
				if (frameIndex < frameCount - 1) 
				{
					ReadCurve(input, frameIndex, timeline);
				}
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.getFrames()[(frameCount - 1) * IkConstraintTimeline.ENTRIES]);
		}

		// Transform constraint timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var index:Int = ReadVarint(input, true);
			var frameCount:Int = ReadVarint(input, true);
			var timeline:TransformConstraintTimeline = new TransformConstraintTimeline(frameCount);
			timeline.transformConstraintIndex = index;
			for (frameIndex in 0...frameCount) 
			{
				timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input));
				if (frameIndex < frameCount - 1) 
				{
					ReadCurve(input, frameIndex, timeline);
				}
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.getFrames()[(frameCount - 1) * TransformConstraintTimeline.ENTRIES]);
		}

		// Path constraint timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var index:Int = ReadVarint(input, true);
			var data:PathConstraintData = skeletonData.pathConstraints[index];
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte(); // ReadSByte(input);
				var frameCount:Int = ReadVarint(input, true);
				switch (timelineType) 
				{
					case PATH_POSITION | PATH_SPACING:
						var timeline:PathConstraintPositionTimeline;
						var timelineScale:Float = 1;
						if (timelineType == PATH_SPACING)
						{
							timeline = new PathConstraintSpacingTimeline(frameCount);
							if (data.spacingMode == SpacingMode.length || data.spacingMode == SpacingMode.fixed) 
							{
								timelineScale = scale; 
							}
						} 
						else 
						{
							timeline = new PathConstraintPositionTimeline(frameCount);
							if (data.positionMode == PositionMode.fixed) 
							{
								timelineScale = scale;
							}
						}
						timeline.pathConstraintIndex = index;
						for (frameIndex in 0...frameCount) 
						{                                    
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input) * timelineScale);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * PathConstraintPositionTimeline.ENTRIES]);
					
					case PATH_MIX:
							var timeline:PathConstraintMixTimeline = new PathConstraintMixTimeline(frameCount);
							timeline.pathConstraintIndex = index;
							for (frameIndex in 0...frameCount) 
							{
								timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input));
								if (frameIndex < frameCount - 1)
								{
									ReadCurve(input, frameIndex, timeline);
								}
							}
							timelines.push(timeline);
							duration = Math.max(duration, timeline.getFrames()[(frameCount - 1) * PathConstraintMixTimeline.ENTRIES]);
					
					default:
						
				}
			}
		}

		// Deform timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var skin:Skin = skeletonData.skins[ReadVarint(input, true)];
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var slotIndex:Int = ReadVarint(input, true);
				var nnn = ReadVarint(input, true);
				for (iii in 0...nnn) 
				{
					var attachment:VertexAttachment = cast skin.getAttachment(slotIndex, ReadString(input));
					var weighted:Bool = (attachment.bones != null);
					var vertices:Array<Float> = attachment.vertices;
					var deformLength:Int = weighted ? Std.int(vertices.length / 3 * 2) : vertices.length;

					var frameCount:Int = ReadVarint(input, true);
					var timeline:DeformTimeline = new DeformTimeline(frameCount);
					timeline.slotIndex = slotIndex;
					timeline.attachment = attachment;
					
					for (frameIndex in 0...frameCount) 
					{
						var time:Float = ReadFloat(input);
						var deform:Array<Float> = null;
						var end:Int = ReadVarint(input, true);
						if (end == 0)
						{
							deform = weighted ? [for (i in 0...deformLength) 0.0] : vertices;
						}
						else 
						{
							deform = [for (i in 0...deformLength) 0.0];
							var start:Int = ReadVarint(input, true);
							end += start;
							if (scale == 1) 
							{
								for (v in start...end)
								{
									deform[v] = ReadFloat(input);
								}
							} 
							else 
							{
								for (v in start...end)
								{
									deform[v] = ReadFloat(input) * scale;
								}
							}
							if (!weighted) 
							{
								var vn = deform.length;
								for (v in 0...vn)
								{
									deform[v] += vertices[v];
								}
							}
						}

						timeline.setFrame(frameIndex, time, deform);
						if (frameIndex < frameCount - 1) 
						{
							ReadCurve(input, frameIndex, timeline);
						}
					}							
					timelines.push(timeline);
					duration = Math.max(duration, timeline.getFrames()[frameCount - 1]);
				}
			}
		}

		// Draw order timeline.
		var drawOrderCount:Int = ReadVarint(input, true);
		if (drawOrderCount > 0) 
		{
			var timeline:DrawOrderTimeline = new DrawOrderTimeline(drawOrderCount);
			var slotCount:Int = skeletonData.slots.length;
			for (i in 0...drawOrderCount) 
			{
				var time:Float = ReadFloat(input);
				var offsetCount:Int = ReadVarint(input, true);
				var drawOrder:Array<Int> = [for (i in 0...slotCount) 0]; // new int[slotCount];
				var ii:Int = slotCount - 1;
				while (ii >= 0)
				{
					drawOrder[ii] = -1;
					ii--;
				}
				var unchanged:Array<Int> = [for (i in 0...(slotCount - offsetCount)) 0]; // new int[slotCount - offsetCount];
				var originalIndex:Int = 0;
				var unchangedIndex:Int = 0;
				for (ii in 0...offsetCount) 
				{
					var slotIndex:Int = ReadVarint(input, true);
					// Collect unchanged items.
					while (originalIndex != slotIndex)
					{
						unchanged[unchangedIndex++] = originalIndex++;
					}
					// Set changed items.
					drawOrder[originalIndex + ReadVarint(input, true)] = originalIndex++;
				}
				// Collect remaining unchanged items.
				while (originalIndex < slotCount)
				{
					unchanged[unchangedIndex++] = originalIndex++;
				}
				// Fill in unchanged items.
				var ii:Int = slotCount - 1;
				while (ii >= 0)
				{
					if (drawOrder[ii] == -1) drawOrder[ii] = unchanged[--unchangedIndex];
					ii--;
				}

				timeline.setFrame(i, time, drawOrder);
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.getFrames()[drawOrderCount - 1]);
		}

		// Event timeline.
		var eventCount:Int = ReadVarint(input, true);
		if (eventCount > 0) 
		{
			var timeline:EventTimeline = new EventTimeline(eventCount);
			for (i in 0...eventCount) 
			{
				var time:Float = ReadFloat(input);
				var eventData:EventData = skeletonData.events[ReadVarint(input, true)];
				var e:Event = new Event(time, eventData);
				e.intValue = ReadVarint(input, false);
				e.floatValue = ReadFloat(input);
				e.stringValue = ReadBoolean(input) ? ReadString(input) : eventData.stringValue;
				if (e.getData().audioPath != null) 
				{
					e.volume = ReadFloat(input);
					e.balance = ReadFloat(input);
				}
				timeline.setFrame(i, e);
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.getFrames()[eventCount - 1]);
		}

		skeletonData.animations.push(new Animation(name, timelines, duration));
	}
	
	private function ReadCurve(input:Input, frameIndex:Int, timeline:CurveTimeline):Void 
	{
		switch (input.readByte()) 
		{
			case CURVE_STEPPED:
				timeline.setStepped(frameIndex);
			
			case CURVE_BEZIER:
				timeline.setCurve(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input));
			
			default:
				
		}
	}
	
	private function ReadSByte(input:Input):Int
	{
		var value:Int = input.readByte();
		if (value == -1) throw "End of stream exception";
		return (value > 127) ? -1 : 1;
	}
	
	private function ReadBoolean(input:Input):Bool
	{
		return (input.readByte() != 0);
	}
	
	private function ReadFloat(input:Input):Float
	{
		floatBuffer.set(3, input.readByte());
		floatBuffer.set(2, input.readByte());
		floatBuffer.set(1, input.readByte());
		floatBuffer.set(0, input.readByte());
		return floatBuffer.getFloat(0);
	}
	
	private function ReadInt(input:Input):RGBA 
	{
		var x:Int = input.readByte();
		var y:Int = input.readByte();
		var z:Int = input.readByte();
		var w:Int = input.readByte();
		return rgba.set(x, y, z, w);
	}
	
	private function ReadVarint(input:Input, optimizePositive:Bool):Int
	{
		var b:Int = input.readByte();
		var result:Int = b & 0x7F;
		if ((b & 0x80) != 0) 
		{
			b = input.readByte();
			result |= (b & 0x7F) << 7;
			if ((b & 0x80) != 0) 
			{
				b = input.readByte();
				result |= (b & 0x7F) << 14;
				if ((b & 0x80) != 0) 
				{
					b = input.readByte();
					result |= (b & 0x7F) << 21;
					if ((b & 0x80) != 0) result |= (input.readByte() & 0x7F) << 28;
				}
			}
		}
		
		return optimizePositive ? result : ((result >> 1) ^ -(result & 1));
	}
	
	private function ReadString(input:Input):String
	{
		var byteCount:Int = ReadVarint(input, true);
		switch (byteCount) 
		{
			case 0:
				return null;
			case 1:
				return "";
			default:
				
		}
		
		byteCount--;
		if (buffer.length < byteCount) buffer = Bytes.alloc(byteCount);
		ReadFully(input, buffer, 0, byteCount);
		return buffer.getString(0, byteCount);
	}

	private static function ReadFully(input:Input, buffer:Bytes, offset:Int, length:Int):Void 
	{
		while (length > 0) 
		{
			var count:Int = input.readBytes(buffer, offset, length);
			if (count <= 0) throw "End of stream exception";
			offset += count;
			length -= count;
		}
	}
	
	/** Scales bone positions, image sizes, and translations as they are loaded. This allows different size images to be used at
     * runtime than were used in Spine.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-loading-skeleton-data#Scaling">Scaling</a> in the Spine Runtimes Guide. */
    #if !spine_no_inline inline #end public function getScale():Float {
        return scale;
    }

    #if !spine_no_inline inline #end public function setScale(scale:Float):Void {
        this.scale = scale;
    }

	private static function IsNullOrEmpty(s:String):Bool
	{
		return (s == null || s.length == 0);
	}
}

class Vertices 
{
	public var bones:Array<Int>;
	public var vertices:Array<Float>;
	
	public function new()
	{
		
	}
}

class RGBA
{
	public var x:Int = 0;
	public var y:Int = 0;
	public var z:Int = 0;
	public var w:Int = 0;
	
	public var floatX(get, null):Float;
	public var floatY(get, null):Float;
	public var floatZ(get, null):Float;
	public var floatW(get, null):Float;

	public function new()
	{
		
	}
	
	public inline function set(x:Int, y:Int, z:Int, w:Int):RGBA
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
		return this;
	}

	private inline function get_floatX():Float
	{
		return (x / 255);
	}

	private inline function get_floatY():Float
	{
		return (y / 255);
	}

	private inline function get_floatZ():Float
	{
		return (z / 255);
	}

	private inline function get_floatW():Float
	{
		return (w / 255);
	}
}