/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated January 1, 2020. Replaces all prior versions.
 *
 * Copyright (c) 2013-2020, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.support.utils.Array;
import spine.support.utils.FloatArray;
import spine.support.utils.IntArray;

import spine.support.utils.ObjectSet;
import spine.support.utils.Pool;
import spine.support.utils.Pool.Poolable;
import spine.support.utils.SnapshotArray;

import spine.Animation.AttachmentTimeline;
import spine.Animation.DrawOrderTimeline;
import spine.Animation.EventTimeline;
import spine.Animation.MixBlend;
import spine.Animation.MixBlend_enum;
import spine.Animation.MixDirection;
import spine.Animation.MixDirection_enum;
import spine.Animation.RotateTimeline;
import spine.Animation.Timeline;

/** Applies animations over time, queues animations for later playback, mixes (crossfading) between animations, and applies
 * multiple animations on top of each other (layering).
 * <p>
 * See <a href='http://esotericsoftware.com/spine-applying-animations/'>Applying Animations</a> in the Spine Runtimes Guide. */
class AnimationState {
    private static var emptyAnimation:Animation = new Animation("<empty>", new Array(0), 0);

    /** 1) A previously applied timeline has set this property.<br>
     * Result: Mix from the current pose to the timeline pose. */
    inline private static var SUBSEQUENT:Int = 0;
    /** 1) This is the first timeline to set this property.<br>
     * 2) The next track entry applied after this one does not have a timeline to set this property.<br>
     * Result: Mix from the setup pose to the timeline pose. */
    inline private static var FIRST:Int = 1;
    /** 1) A previously applied timeline has set this property.<br>
     * 2) The next track entry to be applied does have a timeline to set this property.<br>
     * 3) The next track entry after that one does not have a timeline to set this property.<br>
     * Result: Mix from the current pose to the timeline pose, but do not mix out. This avoids "dipping" when crossfading
     * animations that key the same property. A subsequent timeline will set this property using a mix. */
    inline private static var HOLD_SUBSEQUENT:Int = 2;
    /** 1) This is the first timeline to set this property.<br>
     * 2) The next track entry to be applied does have a timeline to set this property.<br>
     * 3) The next track entry after that one does not have a timeline to set this property.<br>
     * Result: Mix from the setup pose to the timeline pose, but do not mix out. This avoids "dipping" when crossfading animations
     * that key the same property. A subsequent timeline will set this property using a mix. */
    inline private static var HOLD_FIRST:Int = 3;
    /** 1) This is the first timeline to set this property.<br>
     * 2) The next track entry to be applied does have a timeline to set this property.<br>
     * 3) The next track entry after that one does have a timeline to set this property.<br>
     * 4) timelineHoldMix stores the first subsequent track entry that does not have a timeline to set this property.<br>
     * Result: The same as HOLD except the mix percentage from the timelineHoldMix track entry is used. This handles when more than
     * 2 track entries in a row have a timeline that sets the same property.<br>
     * Eg, A -> B -> C -> D where A, B, and C have a timeline setting same property, but D does not. When A is applied, to avoid
     * "dipping" A is not mixed out, however D (the first entry that doesn't set the property) mixing in is used to mix out A
     * (which affects B and C). Without using D to mix out, A would be applied fully until mixing completes, then snap to the mixed
     * out position. */
    inline private static var HOLD_MIX:Int = 4;

    inline private static var SETUP:Int = 1; inline private static var CURRENT:Int = 2;

    private var data:AnimationStateData;
    public var tracks:Array<TrackEntry> = new Array();
    private var events:Array<Event> = new Array();
    public var listeners:SnapshotArray<AnimationStateListener> = new SnapshotArray();
    private var queue:EventQueue = null;
    private var propertyIds:ObjectSet<String> = new ObjectSet();
    public var animationsChanged:Bool = false;
    private var timeScale:Float = 1;
    private var unkeyedState:Int = 0;

    public var trackEntryPool:Pool<TrackEntry> = new TrackEntryPool();

    /** Creates an uninitialized AnimationState. The animation state data must be set before use. */
    /*public function new() {
        this.queue = new EventQueue();
        @:privateAccess this.queue.AnimationState_this = this;
    }*/

    public function new(data:AnimationStateData) {
        this.queue = new EventQueue();
        @:privateAccess this.queue.AnimationState_this = this;
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        this.data = data;
    }

    /** Increments each track entry {@link TrackEntry#getTrackTime()}, setting queued animations as current if needed. */
    #if !spine_no_inline inline #end public function update(delta:Float):Void {
        delta *= timeScale;
        var tracks = this.tracks.items;
        var i:Int = 0; var n:Int = this.tracks.size; while (i < n) {
            var current:TrackEntry = fastCast(tracks[i], TrackEntry);
            if (current == null) { i++; continue; }

            current.animationLast = current.nextAnimationLast;
            current.trackLast = current.nextTrackLast;

            var currentDelta:Float = delta * current.timeScale;

            if (current.delay > 0) {
                current.delay -= currentDelta;
                if (current.delay > 0) { i++; continue; }
                currentDelta = -current.delay;
                current.delay = 0;
            }

            var next:TrackEntry = current.next;
            if (next != null) {
                // When the next entry's delay is passed, change to the next entry, preserving leftover time.
                var nextTime:Float = current.trackLast - next.delay;
                if (nextTime >= 0) {
                    next.delay = 0;
                    next.trackTime += current.timeScale == 0 ? 0 : (nextTime / current.timeScale + delta) * next.timeScale;
                    current.trackTime += currentDelta;
                    setCurrent(i, next, true);
                    while (next.mixingFrom != null) {
                        next.mixTime += delta;
                        next = next.mixingFrom;
                    }
                    { i++; continue; }
                }
            } else if (current.trackLast >= current.trackEnd && current.mixingFrom == null) {
                // Clear the track when there is no next entry, the track end time is reached, and there is no mixingFrom.
                tracks[i] = null;
                queue.end(current);
                clearNext(current);
                { i++; continue; }
            }
            if (current.mixingFrom != null && updateMixingFrom(current, delta)) {
                // End mixing from entries once all have completed.
                var from:TrackEntry = current.mixingFrom;
                current.mixingFrom = null;
                if (from != null) from.mixingTo = null;
                while (from != null) {
                    queue.end(from);
                    from = from.mixingFrom;
                }
            }

            current.trackTime += currentDelta;
        i++; }

        queue.drain();
    }

    /** Returns true when all mixing from entries are complete. */
    #if !spine_no_inline inline #end private function updateMixingFrom(to:TrackEntry, delta:Float):Bool {
        var from:TrackEntry = to.mixingFrom;
        if (from == null) return true;

        var finished:Bool = updateMixingFrom(from, delta);

        from.animationLast = from.nextAnimationLast;
        from.trackLast = from.nextTrackLast;

        // Require mixTime > 0 to ensure the mixing from entry was applied at least once.
        if (to.mixTime > 0 && to.mixTime >= to.mixDuration) {
            // Require totalAlpha == 0 to ensure mixing is complete, unless mixDuration == 0 (the transition is a single frame).
            if (from.totalAlpha == 0 || to.mixDuration == 0) {
                to.mixingFrom = from.mixingFrom;
                if (from.mixingFrom != null) from.mixingFrom.mixingTo = to;
                to.interruptAlpha = from.interruptAlpha;
                queue.end(from);
            }
            return finished;
        }

        from.trackTime += delta * from.timeScale;
        to.mixTime += delta;
        return false;
    }

    /** Poses the skeleton using the track entry animations. The animation state is not changed, so can be applied to multiple
     * skeletons to pose them identically.
     * @return True if any animations were applied. */
    public function apply(skeleton:Skeleton):Bool {
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        if (animationsChanged) handleAnimationsChanged();

        var events:Array<Event> = this.events;
        var applied:Bool = false;
        var tracks = this.tracks.items;
        var i:Int = 0; var n:Int = this.tracks.size; while (i < n) {
            var current:TrackEntry = fastCast(tracks[i], TrackEntry);
            if (current == null || current.delay > 0) { i++; continue; }
            applied = true;

            // Track 0 animations aren't for layering, so do not show the previously applied animations before the first key.
            var blend:MixBlend = i == 0 ? MixBlend.first : current.mixBlend;

            // Apply mixing from entries first.
            var mix:Float = current.alpha;
            if (current.mixingFrom != null)
                mix *= applyMixingFrom(current, skeleton, blend);
            else if (current.trackTime >= current.trackEnd && current.next == null) //
                mix = 0; // Set to setup pose the last time the entry will be applied.

            // Apply current entry.
            var animationLast:Float = current.animationLast; var animationTime:Float = current.getAnimationTime(); var applyTime:Float = animationTime;
            var applyEvents:Array<Event> = events;
            if (current.reverse) {
                applyTime = current.animation.duration - applyTime;
                applyEvents = null;
            }
            var timelineCount:Int = current.animation.timelines.size;
            var timelines = current.animation.timelines.items;
            if ((i == 0 && mix == 1) || blend == MixBlend.add) {
                var ii:Int = 0; while (ii < timelineCount) {
                    var timeline:Dynamic = timelines[ii];
                    if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, AttachmentTimeline))
                        applyAttachmentTimeline(fastCast(timeline, AttachmentTimeline), skeleton, applyTime, blend, true);
                    else
                        (fastCast(timeline, Timeline)).apply(skeleton, animationLast, applyTime, applyEvents, mix, blend, MixDirection.directionIn);
                ii++; }
            } else {
                var timelineMode:IntArray = current.timelineMode.items;

                var firstFrame:Bool = current.timelinesRotation.size != timelineCount << 1;
                if (firstFrame) current.timelinesRotation.setSize(timelineCount << 1);
                var timelinesRotation:FloatArray = current.timelinesRotation.items;

                var ii:Int = 0; while (ii < timelineCount) {
                    var timeline:Timeline = fastCast(timelines[ii], Timeline);
                    var timelineBlend:MixBlend = timelineMode[ii] == SUBSEQUENT ? blend : MixBlend.setup;
                    if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, RotateTimeline)) {
                        applyRotateTimeline(fastCast(timeline, RotateTimeline), skeleton, applyTime, mix, timelineBlend, timelinesRotation,
                            ii << 1, firstFrame);
                    } else if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, AttachmentTimeline))
                        applyAttachmentTimeline(fastCast(timeline, AttachmentTimeline), skeleton, applyTime, blend, true);
                    else
                        timeline.apply(skeleton, animationLast, applyTime, applyEvents, mix, timelineBlend, MixDirection.directionIn);
                ii++; }
            }
            queueEvents(current, animationTime);
            events.clear();
            current.nextAnimationLast = animationTime;
            current.nextTrackLast = current.trackTime;
        i++; }

        // Set slots attachments to the setup pose, if needed. This occurs if an animation that is mixing out sets attachments so
        // subsequent timelines see any deform, but the subsequent timelines don't set an attachment (eg they are also mixing out or
        // the time is before the first key).
        var setupState:Int = unkeyedState + SETUP;
        var slots = skeleton.slots.items;
        var i:Int = 0; var n:Int = skeleton.slots.size; while (i < n) {
            var slot:Slot = fastCast(slots[i], Slot);
            if (slot.attachmentState == setupState) {
                var attachmentName:String = slot.data.attachmentName;
                slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slot.data.index, attachmentName));
            }
        i++; }
        unkeyedState += 2; // Increasing after each use avoids the need to reset attachmentState for every slot.

        queue.drain();
        return applied;
    }

    private function applyMixingFrom(to:TrackEntry, skeleton:Skeleton, blend:MixBlend):Float {
        var from:TrackEntry = to.mixingFrom;
        if (from.mixingFrom != null) applyMixingFrom(from, skeleton, blend);

        var mix:Float = 0;
        if (to.mixDuration == 0) { // Single frame mix to undo mixingFrom changes.
            mix = 1;
            if (blend == MixBlend.first) blend = MixBlend.setup; // Tracks >0 are transparent and can't reset to setup pose.
        } else {
            mix = to.mixTime / to.mixDuration;
            if (mix > 1) mix = 1;
            if (blend != MixBlend.first) blend = from.mixBlend; // Track 0 ignores track mix blend.
        }

        var attachments:Bool = mix < from.attachmentThreshold; var drawOrder:Bool = mix < from.drawOrderThreshold;
        var timelineCount:Int = from.animation.timelines.size;
        var timelines = from.animation.timelines.items;
        var alphaHold:Float = from.alpha * to.interruptAlpha; var alphaMix:Float = alphaHold * (1 - mix);
        var animationLast:Float = from.animationLast; var animationTime:Float = from.getAnimationTime(); var applyTime:Float = animationTime;
        var events:Array<Event> = null;
        if (from.reverse)
            applyTime = from.animation.duration - applyTime;
        else {
            if (mix < from.eventThreshold) events = this.events;
        }

        if (blend == MixBlend.add) {
            var i:Int = 0; while (i < timelineCount) {
                (fastCast(timelines[i], Timeline)).apply(skeleton, animationLast, applyTime, events, alphaMix, blend, MixDirection.directionOut); i++; }
        } else {
            var timelineMode:IntArray = from.timelineMode.items;
            var timelineHoldMix = from.timelineHoldMix.items;

            var firstFrame:Bool = from.timelinesRotation.size != timelineCount << 1;
            if (firstFrame) from.timelinesRotation.setSize(timelineCount << 1);
            var timelinesRotation:FloatArray = from.timelinesRotation.items;

            from.totalAlpha = 0;
            var i:Int = 0; while (i < timelineCount) {
                var timeline:Timeline = fastCast(timelines[i], Timeline);
                var direction:MixDirection = MixDirection.directionOut;
                var timelineBlend:MixBlend = 0;
                var alpha:Float = 0;
                var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (timelineMode[i]); {
                if (_switchCond0 == SUBSEQUENT) {
                    if (!drawOrder && #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, DrawOrderTimeline)) { _continueAfterSwitch0 = true; break; }
                    timelineBlend = blend;
                    alpha = alphaMix;
                    break;
                } else if (_switchCond0 == FIRST) {
                    timelineBlend = MixBlend.setup;
                    alpha = alphaMix;
                    break;
                } else if (_switchCond0 == HOLD_SUBSEQUENT) {
                    timelineBlend = blend;
                    alpha = alphaHold;
                    break;
                } else if (_switchCond0 == HOLD_FIRST) {
                    timelineBlend = MixBlend.setup;
                    alpha = alphaHold;
                    break;
                } else {
                    // HOLD_MIX
                    timelineBlend = MixBlend.setup;
                    var holdMix:TrackEntry = fastCast(timelineHoldMix[i], TrackEntry);
                    alpha = alphaHold * MathUtils.max(0, Std.int(1 - holdMix.mixTime / holdMix.mixDuration));
                    break;
                } } break; } if (_continueAfterSwitch0) { i++; continue; }
                from.totalAlpha += alpha;
                if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, RotateTimeline)) {
                    applyRotateTimeline(fastCast(timeline, RotateTimeline), skeleton, applyTime, alpha, timelineBlend, timelinesRotation, i << 1,
                        firstFrame);
                } else if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, AttachmentTimeline))
                    applyAttachmentTimeline(fastCast(timeline, AttachmentTimeline), skeleton, applyTime, timelineBlend, attachments);
                else {
                    if (drawOrder && #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, DrawOrderTimeline) && timelineBlend == MixBlend.setup)
                        direction = MixDirection.directionIn;
                    timeline.apply(skeleton, animationLast, applyTime, events, alpha, timelineBlend, direction);
                }
            i++; }
        }

        if (to.mixDuration > 0) queueEvents(from, animationTime);
        this.events.clear();
        from.nextAnimationLast = animationTime;
        from.nextTrackLast = from.trackTime;

        return mix;
    }

    /** Applies the attachment timeline and sets {@link Slot#attachmentState}.
     * @param attachments False when: 1) the attachment timeline is mixing out, 2) mix < attachmentThreshold, and 3) the timeline
     *           is not the last timeline to set the slot's attachment. In that case the timeline is applied only so subsequent
     *           timelines see any deform. */
    #if !spine_no_inline inline #end private function applyAttachmentTimeline(timeline:AttachmentTimeline, skeleton:Skeleton, time:Float, blend:MixBlend, attachments:Bool):Void {

        var slot:Slot = skeleton.slots.get(timeline.slotIndex);
        if (!slot.bone.active) return;

        if (time < timeline.frames[0]) { // Time is before first frame.
            if (blend == MixBlend.setup || blend == MixBlend.first)
                setAttachment(skeleton, slot, slot.data.attachmentName, attachments);
        } else
            setAttachment(skeleton, slot, timeline.attachmentNames[Timeline.search(timeline.frames, time)], attachments);

        // If an attachment wasn't set (ie before the first frame or attachments is false), set the setup attachment later.
        if (slot.attachmentState <= unkeyedState) slot.attachmentState = unkeyedState + SETUP;
    }

    private function setAttachment(skeleton:Skeleton, slot:Slot, attachmentName:String, attachments:Bool):Void {
        slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slot.data.index, attachmentName));
        if (attachments) slot.attachmentState = unkeyedState + CURRENT;
    }

    /** Applies the rotate timeline, mixing with the current pose while keeping the same rotation direction chosen as the shortest
     * the first time the mixing was applied. */
    private function applyRotateTimeline(timeline:RotateTimeline, skeleton:Skeleton, time:Float, alpha:Float, blend:MixBlend, timelinesRotation:FloatArray, i:Int, firstFrame:Bool):Void {

        if (firstFrame) timelinesRotation[i] = 0;

        if (alpha == 1) {
            timeline.apply(skeleton, 0, time, null, 1, blend, MixDirection.directionIn);
            return;
        }

        var bone:Bone = skeleton.bones.get(timeline.boneIndex);
        if (!bone.active) return;
        var frames:FloatArray = timeline.frames;
        var r1:Float = 0; var r2:Float = 0;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch1 = false; while(true) { var _switchCond1 = (blend); {
            if (_switchCond1 == setup) {
                bone.rotation = bone.data.rotation;
                // Fall through.
                return;
                r1 = bone.rotation;
                r2 = bone.data.rotation;
            } else if (_switchCond1 == first) {
                r1 = bone.rotation;
                r2 = bone.data.rotation;
            } else {
                return;
                r1 = bone.rotation;
                r2 = bone.data.rotation;
            } } break; }
        } else {
            r1 = blend == MixBlend.setup ? bone.data.rotation : bone.rotation;
            r2 = bone.data.rotation + timeline.getCurveValue(time);
        }

        // Mix between rotations using the direction of the shortest route on the first frame.
        var total:Float = 0; var diff:Float = r2 - r1;
        diff -= (16384 - Std.int((16384.499999999996 - diff / 360))) * 360;
        if (diff == 0)
            total = timelinesRotation[i];
        else {
            var lastTotal:Float = 0; var lastDiff:Float = 0;
            if (firstFrame) {
                lastTotal = 0;
                lastDiff = diff;
            } else {
                lastTotal = timelinesRotation[i]; // Angle and direction of mix, including loops.
                lastDiff = timelinesRotation[i + 1]; // Difference between bones.
            }
            var current:Bool = diff > 0; var dir:Bool = lastTotal >= 0;
            // Detect cross at 0 (not 180).
            if (MathUtils.signum(lastDiff) != MathUtils.signum(diff) && Math.abs(lastDiff) <= 90) {
                // A cross after a 360 rotation is a loop.
                if (Math.abs(lastTotal) > 180) lastTotal += 360 * MathUtils.signum(lastTotal);
                dir = current;
            }
            total = diff + lastTotal - lastTotal % 360; // Store loops as part of lastTotal.
            if (dir != current) total += 360 * MathUtils.signum(lastTotal);
            timelinesRotation[i] = total;
        }
        timelinesRotation[i + 1] = diff;
        bone.rotation = r1 + total * alpha;
    }

    #if !spine_no_inline inline #end private function queueEvents(entry:TrackEntry, animationTime:Float):Void {
        var animationStart:Float = entry.animationStart; var animationEnd:Float = entry.animationEnd;
        var duration:Float = animationEnd - animationStart;
        var trackLastWrapped:Float = entry.trackLast % duration;

        // Queue events before complete.
        var events = this.events.items;
        var i:Int = 0; var n:Int = this.events.size;
        while (i < n) {
            var event:Event = fastCast(events[i], Event);
            if (event.time < trackLastWrapped) break;
            if (event.time > animationEnd) { i++; continue; } // Discard events outside animation start/end.
            queue.event(entry, event);
        i++; }

        // Queue complete if completed a loop iteration or the animation.
        var complete:Bool = false;
        if (entry.loop)
            complete = duration == 0 || trackLastWrapped > entry.trackTime % duration;
        else
            complete = animationTime >= animationEnd && entry.animationLast < animationEnd;
        if (complete) queue.complete(entry);

        // Queue events after complete.
        while (i < n) {
            var event:Event = fastCast(events[i], Event);
            if (event.time < animationStart) { i++; continue; } // Discard events outside animation start/end.
            queue.event(entry, event);
        i++; }
    }

    /** Removes all animations from all tracks, leaving skeletons in their current pose.
     * <p>
     * It may be desired to use {@link AnimationState#setEmptyAnimations(float)} to mix the skeletons back to the setup pose,
     * rather than leaving them in their current pose. */
    #if !spine_no_inline inline #end public function clearTracks():Void {
        var oldDrainDisabled:Bool = queue.drainDisabled;
        queue.drainDisabled = true;
        var i:Int = 0; var n:Int = tracks.size; while (i < n) {
            clearTrack(i); i++; }
        tracks.clear();
        queue.drainDisabled = oldDrainDisabled;
        queue.drain();
    }

    /** Removes all animations from the track, leaving skeletons in their current pose.
     * <p>
     * It may be desired to use {@link AnimationState#setEmptyAnimation(int, float)} to mix the skeletons back to the setup pose,
     * rather than leaving them in their current pose. */
    #if !spine_no_inline inline #end public function clearTrack(trackIndex:Int):Void {
        if (trackIndex < 0) throw new IllegalArgumentException("trackIndex must be >= 0.");
        if (trackIndex >= tracks.size) return;
        var current:TrackEntry = tracks.get(trackIndex);
        if (current == null) return;

        queue.end(current);

        clearNext(current);

        var entry:TrackEntry = current;
        while (true) {
            var from:TrackEntry = entry.mixingFrom;
            if (from == null) break;
            queue.end(from);
            entry.mixingFrom = null;
            entry.mixingTo = null;
            entry = from;
        }

        tracks.set(current.trackIndex, null);

        queue.drain();
    }

    #if !spine_no_inline inline #end private function setCurrent(index:Int, current:TrackEntry, interrupt:Bool):Void {
        var from:TrackEntry = expandToIndex(index);
        tracks.set(index, current);
        current.previous = null;

        if (from != null) {
            if (interrupt) queue.interrupt(from);
            current.mixingFrom = from;
            from.mixingTo = current;
            current.mixTime = 0;

            // Store the interrupted mix percentage.
            if (from.mixingFrom != null && from.mixDuration > 0)
                current.interruptAlpha *= MathUtils.min(1, Std.int(from.mixTime / from.mixDuration));

            from.timelinesRotation.clear(); // Reset rotation for mixing out, in case entry was mixed in.
        }

        queue.start(current);
    }

    /** Sets an animation by name.
     * <p>
     * See {@link #setAnimation(int, Animation, boolean)}. */
    #if !spine_no_inline inline #end public function setAnimationByName(trackIndex:Int, animationName:String, loop:Bool):TrackEntry {
        var animation:Animation = data.skeletonData.findAnimation(animationName);
        if (animation == null) throw new IllegalArgumentException("Animation not found: " + animationName);
        return setAnimation(trackIndex, animation, loop);
    }

    /** Sets the current animation for a track, discarding any queued animations. If the formerly current track entry was never
     * applied to a skeleton, it is replaced (not mixed from).
     * @param loop If true, the animation will repeat. If false it will not, instead its last frame is applied if played beyond its
     *           duration. In either case {@link TrackEntry#getTrackEnd()} determines when the track is cleared.
     * @return A track entry to allow further customization of animation playback. References to the track entry must not be kept
     *         after the {@link AnimationStateListener#dispose(TrackEntry)} event occurs. */
    #if !spine_no_inline inline #end public function setAnimation(trackIndex:Int, animation:Animation, loop:Bool):TrackEntry {
        if (trackIndex < 0) throw new IllegalArgumentException("trackIndex must be >= 0.");
        if (animation == null) throw new IllegalArgumentException("animation cannot be null.");
        var interrupt:Bool = true;
        var current:TrackEntry = expandToIndex(trackIndex);
        if (current != null) {
            if (current.nextTrackLast == -1) {
                // Don't mix from an entry that was never applied.
                tracks.set(trackIndex, current.mixingFrom);
                queue.interrupt(current);
                queue.end(current);
                clearNext(current);
                current = current.mixingFrom;
                interrupt = false; // mixingFrom is current again, but don't interrupt it twice.
            } else
                clearNext(current);
        }
        var entry:TrackEntry = trackEntry(trackIndex, animation, loop, current);
        setCurrent(trackIndex, entry, interrupt);
        queue.drain();
        return entry;
    }

    /** Queues an animation by name.
     * <p>
     * See {@link #addAnimation(int, Animation, boolean, float)}. */
    #if !spine_no_inline inline #end public function addAnimationByName(trackIndex:Int, animationName:String, loop:Bool, delay:Float):TrackEntry {
        var animation:Animation = data.skeletonData.findAnimation(animationName);
        if (animation == null) throw new IllegalArgumentException("Animation not found: " + animationName);
        return addAnimation(trackIndex, animation, loop, delay);
    }

    /** Adds an animation to be played after the current or last queued animation for a track. If the track is empty, it is
     * equivalent to calling {@link #setAnimation(int, Animation, boolean)}.
     * @param delay If > 0, sets {@link TrackEntry#getDelay()}. If <= 0, the delay set is the duration of the previous track entry
     *           minus any mix duration (from the {@link AnimationStateData}) plus the specified <code>delay</code> (ie the mix
     *           ends at (<code>delay</code> = 0) or before (<code>delay</code> < 0) the previous track entry duration). If the
     *           previous entry is looping, its next loop completion is used instead of its duration.
     * @return A track entry to allow further customization of animation playback. References to the track entry must not be kept
     *         after the {@link AnimationStateListener#dispose(TrackEntry)} event occurs. */
    #if !spine_no_inline inline #end public function addAnimation(trackIndex:Int, animation:Animation, loop:Bool, delay:Float):TrackEntry {
        if (trackIndex < 0) throw new IllegalArgumentException("trackIndex must be >= 0.");
        if (animation == null) throw new IllegalArgumentException("animation cannot be null.");

        var last:TrackEntry = expandToIndex(trackIndex);
        if (last != null) {
            while (last.next != null) {
                last = last.next; }
        }

        var entry:TrackEntry = trackEntry(trackIndex, animation, loop, last);

        if (last == null) {
            setCurrent(trackIndex, entry, true);
            queue.drain();
        } else {
            last.next = entry;
            entry.previous = last;
            if (delay <= 0) delay += last.getTrackComplete() - entry.mixDuration;
        }

        entry.delay = delay;
        return entry;
    }

    /** Sets an empty animation for a track, discarding any queued animations, and sets the track entry's
     * {@link TrackEntry#getMixDuration()}. An empty animation has no timelines and serves as a placeholder for mixing in or out.
     * <p>
     * Mixing out is done by setting an empty animation with a mix duration using either {@link #setEmptyAnimation(int, float)},
     * {@link #setEmptyAnimations(float)}, or {@link #addEmptyAnimation(int, float, float)}. Mixing to an empty animation causes
     * the previous animation to be applied less and less over the mix duration. Properties keyed in the previous animation
     * transition to the value from lower tracks or to the setup pose value if no lower tracks key the property. A mix duration of
     * 0 still mixes out over one frame.
     * <p>
     * Mixing in is done by first setting an empty animation, then adding an animation using
     * {@link #addAnimation(int, Animation, boolean, float)} with the desired delay (an empty animation has a duration of 0) and on
     * the returned track entry, set the {@link TrackEntry#setMixDuration(float)}. Mixing from an empty animation causes the new
     * animation to be applied more and more over the mix duration. Properties keyed in the new animation transition from the value
     * from lower tracks or from the setup pose value if no lower tracks key the property to the value keyed in the new
     * animation. */
    #if !spine_no_inline inline #end public function setEmptyAnimation(trackIndex:Int, mixDuration:Float):TrackEntry {
        var entry:TrackEntry = setAnimation(trackIndex, emptyAnimation, false);
        entry.mixDuration = mixDuration;
        entry.trackEnd = mixDuration;
        return entry;
    }

    /** Adds an empty animation to be played after the current or last queued animation for a track, and sets the track entry's
     * {@link TrackEntry#getMixDuration()}. If the track is empty, it is equivalent to calling
     * {@link #setEmptyAnimation(int, float)}.
     * <p>
     * See {@link #setEmptyAnimation(int, float)}.
     * @param delay If > 0, sets {@link TrackEntry#getDelay()}. If <= 0, the delay set is the duration of the previous track entry
     *           minus any mix duration plus the specified <code>delay</code> (ie the mix ends at (<code>delay</code> = 0) or
     *           before (<code>delay</code> < 0) the previous track entry duration). If the previous entry is looping, its next
     *           loop completion is used instead of its duration.
     * @return A track entry to allow further customization of animation playback. References to the track entry must not be kept
     *         after the {@link AnimationStateListener#dispose(TrackEntry)} event occurs. */
    #if !spine_no_inline inline #end public function addEmptyAnimation(trackIndex:Int, mixDuration:Float, delay:Float):TrackEntry {
        var entry:TrackEntry = addAnimation(trackIndex, emptyAnimation, false, delay <= 0 ? 1 : delay);
        entry.mixDuration = mixDuration;
        entry.trackEnd = mixDuration;
        if (delay <= 0 && entry.previous != null) entry.delay = entry.previous.getTrackComplete() - entry.mixDuration + delay;
        return entry;
    }

    /** Sets an empty animation for every track, discarding any queued animations, and mixes to it over the specified mix
     * duration. */
    #if !spine_no_inline inline #end public function setEmptyAnimations(mixDuration:Float):Void {
        var oldDrainDisabled:Bool = queue.drainDisabled;
        queue.drainDisabled = true;
        var tracks = this.tracks.items;
        var i:Int = 0; var n:Int = this.tracks.size; while (i < n) {
            var current:TrackEntry = fastCast(tracks[i], TrackEntry);
            if (current != null) setEmptyAnimation(current.trackIndex, mixDuration);
        i++; }
        queue.drainDisabled = oldDrainDisabled;
        queue.drain();
    }

    #if !spine_no_inline inline #end private function expandToIndex(index:Int):TrackEntry {
        if (index < tracks.size) return tracks.get(index);
        tracks.ensureCapacity(index - tracks.size + 1);
        tracks.size = index + 1;
        return null;
    }

    #if !spine_no_inline inline #end private function trackEntry(trackIndex:Int, animation:Animation, loop:Bool, last:TrackEntry):TrackEntry {
        var entry:TrackEntry = trackEntryPool.obtain();
        entry.trackIndex = trackIndex;
        entry.animation = animation;
        entry.loop = loop;
        entry.holdPrevious = false;

        entry.eventThreshold = 0;
        entry.attachmentThreshold = 0;
        entry.drawOrderThreshold = 0;

        entry.animationStart = 0;
        entry.animationEnd = animation.getDuration();
        entry.animationLast = -1;
        entry.nextAnimationLast = -1;

        entry.delay = 0;
        entry.trackTime = 0;
        entry.trackLast = -1;
        entry.nextTrackLast = -1;
        entry.trackEnd = 999999999.0;
        entry.timeScale = 1;

        entry.alpha = 1;
        entry.interruptAlpha = 1;
        entry.mixTime = 0;
        entry.mixDuration = last == null ? 0 : data.getMix(last.animation, animation);
        entry.mixBlend = MixBlend.replace;
        return entry;
    }

    /** Removes the {@link TrackEntry#getNext() next entry} and all entries after it for the specified entry. */
    #if !spine_no_inline inline #end public function clearNext(entry:TrackEntry):Void {
        var next:TrackEntry = entry.next;
        while (next != null) {
            queue.dispose(next);
            next = next.next;
        }
        entry.next = null;
    }

    #if !spine_no_inline inline #end public function handleAnimationsChanged():Void {
        animationsChanged = false;

        // Process in the order that animations are applied.
        propertyIds.clear(2048);
        var n:Int = tracks.size;
        var tracks = this.tracks.items;
        var i:Int = 0; while (i < n) {
            var entry:TrackEntry = fastCast(tracks[i], TrackEntry);
            if (entry == null) { i++; continue; }
            while (entry.mixingFrom != null) { // Move to last entry, then iterate in reverse.
                entry = entry.mixingFrom; }
            do {
                if (entry.mixingTo == null || entry.mixBlend != MixBlend.add) computeHold(entry);
                entry = entry.mixingTo;
            } while (entry != null);
        i++; }
    }

    #if !spine_no_inline inline #end private function computeHold(entry:TrackEntry):Void {
        var to:TrackEntry = entry.mixingTo;
        var timelines = entry.animation.timelines.items;
        var timelinesCount:Int = entry.animation.timelines.size;
        var timelineMode:IntArray = entry.timelineMode.setSize(timelinesCount);
        entry.timelineHoldMix.clear();
        var timelineHoldMix = entry.timelineHoldMix.setSize(timelinesCount);
        var propertyIds:ObjectSet<String> = this.propertyIds;

        if (to != null && to.holdPrevious) {
            var i:Int = 0; while (i < timelinesCount) {
                timelineMode[i] = propertyIds.addAll((fastCast(timelines[i], Timeline)).getPropertyIds()) ? HOLD_FIRST : HOLD_SUBSEQUENT; i++; }
            return;
        }

        var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
        var i:Int = 0; while (i < timelinesCount) {
            var timeline:Timeline = fastCast(timelines[i], Timeline);
            var ids:StringArray = timeline.getPropertyIds();
            if (!propertyIds.addAll(ids))
                timelineMode[i] = SUBSEQUENT;
            else if (to == null || #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, AttachmentTimeline) || #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, DrawOrderTimeline)
                || #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(timeline, EventTimeline) || !to.animation.hasTimeline(ids)) {
                timelineMode[i] = FIRST;
            } else {
                var next:TrackEntry = to.mixingTo; while (next != null) {
                    if (next.animation.hasTimeline(ids)) { next = next.mixingTo; continue; }
                    if (next.mixDuration > 0) {
                        timelineMode[i] = HOLD_MIX;
                        timelineHoldMix[i] = next;
                        { next = next.mixingTo; _gotoLabel_outer = 2; break; }
                    }
                    break;
                next = next.mixingTo; } if (_gotoLabel_outer == 2) { _gotoLabel_outer = 0; { i++; continue; } } if (_gotoLabel_outer >= 1) break;
                timelineMode[i] = HOLD_FIRST;
            }
        i++; } if (_gotoLabel_outer == 0) break; }
    }

    /** Returns the track entry for the animation currently playing on the track, or null if no animation is currently playing. */
    #if !spine_no_inline inline #end public function getCurrent(trackIndex:Int):TrackEntry {
        if (trackIndex < 0) throw new IllegalArgumentException("trackIndex must be >= 0.");
        if (trackIndex >= tracks.size) return null;
        return tracks.get(trackIndex);
    }

    /** Adds a listener to receive events for all track entries. */
    #if !spine_no_inline inline #end public function addListener(listener:AnimationStateListener):Void {
        if (listener == null) throw new IllegalArgumentException("listener cannot be null.");
        listeners.add(listener);
    }

    /** Removes the listener added with {@link #addListener(AnimationStateListener)}. */
    #if !spine_no_inline inline #end public function removeListener(listener:AnimationStateListener):Void {
        listeners.removeValue(listener, true);
    }

    /** Removes all listeners added with {@link #addListener(AnimationStateListener)}. */
    #if !spine_no_inline inline #end public function clearListeners():Void {
        listeners.clear();
    }

    /** Discards all listener notifications that have not yet been delivered. This can be useful to call from an
     * {@link AnimationStateListener} when it is known that further notifications that may have been already queued for delivery
     * are not wanted because new animations are being set. */
    #if !spine_no_inline inline #end public function clearListenerNotifications():Void {
        queue.clear();
    }

    /** Multiplier for the delta time when the animation state is updated, causing time for all animations and mixes to play slower
     * or faster. Defaults to 1.
     * <p>
     * See TrackEntry {@link TrackEntry#getTimeScale()} for affecting a single animation. */
    #if !spine_no_inline inline #end public function getTimeScale():Float {
        return timeScale;
    }

    #if !spine_no_inline inline #end public function setTimeScale(timeScale:Float):Void {
        this.timeScale = timeScale;
    }

    /** The AnimationStateData to look up mix durations. */
    #if !spine_no_inline inline #end public function getData():AnimationStateData {
        return data;
    }

    #if !spine_no_inline inline #end public function setData(data:AnimationStateData):Void {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        this.data = data;
    }

    /** The list of tracks that have had animations, which may contain null entries for tracks that currently have no animation. */
    #if !spine_no_inline inline #end public function getTracks():Array<TrackEntry> {
        return tracks;
    }

    #if !spine_no_inline inline #end public function toString():String {
        var buffer:StringBuilder = new StringBuilder(64);
        var tracks = this.tracks.items;
        var i:Int = 0; var n:Int = this.tracks.size; while (i < n) {
            var entry:TrackEntry = fastCast(tracks[i], TrackEntry);
            if (entry == null) { i++; continue; }
            if (buffer.length() > 0) buffer.append(", ");
            buffer.append(entry.toString());
        i++; }
        if (buffer.length() == 0) return "<none>";
        return buffer.toString();
    }
}

/** Stores settings and other state for the playback of an animation on an {@link AnimationState} track.
 * <p>
 * References to a track entry must not be kept after the {@link AnimationStateListener#dispose(TrackEntry)} event occurs. */
class TrackEntry implements Poolable {
    public var animation:Animation;
    public var previous:TrackEntry; public var next:TrackEntry = null; public var mixingFrom:TrackEntry = null; public var mixingTo:TrackEntry = null;
    public var listener:AnimationStateListener;
    public var trackIndex:Int = 0;
    public var loop:Bool = false; public var holdPrevious:Bool = false; public var reverse:Bool = false;
    public var eventThreshold:Float = 0; public var attachmentThreshold:Float = 0; public var drawOrderThreshold:Float = 0;
    public var animationStart:Float = 0; public var animationEnd:Float = 0; public var animationLast:Float = 0; public var nextAnimationLast:Float = 0;
    public var delay:Float = 0; public var trackTime:Float = 0; public var trackLast:Float = 0; public var nextTrackLast:Float = 0; public var trackEnd:Float = 0; public var timeScale:Float = 0;
    public var alpha:Float = 0; public var mixTime:Float = 0; public var mixDuration:Float = 0; public var interruptAlpha:Float = 0; public var totalAlpha:Float = 0;
    public var mixBlend:MixBlend = MixBlend.replace;

    public var timelineMode:IntArray = new IntArray();
    public var timelineHoldMix:Array<TrackEntry> = new Array();
    public var timelinesRotation:FloatArray = new FloatArray();

    #if !spine_no_inline inline #end public function reset():Void {
        previous = null;
        next = null;
        mixingFrom = null;
        mixingTo = null;
        animation = null;
        listener = null;
        timelineMode.clear();
        timelineHoldMix.clear();
        timelinesRotation.clear();
    }

    /** The index of the track where this track entry is either current or queued.
     * <p>
     * See {@link AnimationState#getCurrent(int)}. */
    #if !spine_no_inline inline #end public function getTrackIndex():Int {
        return trackIndex;
    }

    /** The animation to apply for this track entry. */
    #if !spine_no_inline inline #end public function getAnimation():Animation {
        return animation;
    }

    #if !spine_no_inline inline #end public function setAnimation(animation:Animation):Void {
        if (animation == null) throw new IllegalArgumentException("animation cannot be null.");
        this.animation = animation;
    }

    /** If true, the animation will repeat. If false it will not, instead its last frame is applied if played beyond its
     * duration. */
    #if !spine_no_inline inline #end public function getLoop():Bool {
        return loop;
    }

    #if !spine_no_inline inline #end public function setLoop(loop:Bool):Void {
        this.loop = loop;
    }

    /** Seconds to postpone playing the animation. When this track entry is the current track entry, <code>delay</code>
     * postpones incrementing the {@link #getTrackTime()}. When this track entry is queued, <code>delay</code> is the time from
     * the start of the previous animation to when this track entry will become the current track entry (ie when the previous
     * track entry {@link TrackEntry#getTrackTime()} >= this track entry's <code>delay</code>).
     * <p>
     * {@link #getTimeScale()} affects the delay.
     * <p>
     * When using {@link AnimationState#addAnimation(int, Animation, boolean, float)} with a <code>delay</code> <= 0, the delay
     * is set using the mix duration from the {@link AnimationStateData}. If {@link #mixDuration} is set afterward, the delay
     * may need to be adjusted. */
    #if !spine_no_inline inline #end public function getDelay():Float {
        return delay;
    }

    #if !spine_no_inline inline #end public function setDelay(delay:Float):Void {
        this.delay = delay;
    }

    /** Current time in seconds this track entry has been the current track entry. The track time determines
     * {@link #getAnimationTime()}. The track time can be set to start the animation at a time other than 0, without affecting
     * looping. */
    #if !spine_no_inline inline #end public function getTrackTime():Float {
        return trackTime;
    }

    #if !spine_no_inline inline #end public function setTrackTime(trackTime:Float):Void {
        this.trackTime = trackTime;
    }

    /** The track time in seconds when this animation will be removed from the track. Defaults to the highest possible float
     * value, meaning the animation will be applied until a new animation is set or the track is cleared. If the track end time
     * is reached, no other animations are queued for playback, and mixing from any previous animations is complete, then the
     * properties keyed by the animation are set to the setup pose and the track is cleared.
     * <p>
     * It may be desired to use {@link AnimationState#addEmptyAnimation(int, float, float)} rather than have the animation
     * abruptly cease being applied. */
    #if !spine_no_inline inline #end public function getTrackEnd():Float {
        return trackEnd;
    }

    public function setTrackEnd(trackEnd:Float):Void {
        this.trackEnd = trackEnd;
    }

    /** If this track entry is non-looping, the track time in seconds when {@link #getAnimationEnd()} is reached, or the current
     * {@link #getTrackTime()} if it has already been reached. If this track entry is looping, the track time when this
     * animation will reach its next {@link #getAnimationEnd()} (the next loop completion). */
    public function getTrackComplete():Float {
        var duration:Float = animationEnd - animationStart;
        if (duration != 0) {
            if (loop) return duration * (1 + Std.int((trackTime / duration))); // Completion of next loop.
            if (trackTime < duration) return duration; // Before duration.
        }
        return trackTime; // Next update.
    }

    /** Seconds when this animation starts, both initially and after looping. Defaults to 0.
     * <p>
     * When changing the <code>animationStart</code> time, it often makes sense to set {@link #getAnimationLast()} to the same
     * value to prevent timeline keys before the start time from triggering. */
    #if !spine_no_inline inline #end public function getAnimationStart():Float {
        return animationStart;
    }

    #if !spine_no_inline inline #end public function setAnimationStart(animationStart:Float):Void {
        this.animationStart = animationStart;
    }

    /** Seconds for the last frame of this animation. Non-looping animations won't play past this time. Looping animations will
     * loop back to {@link #getAnimationStart()} at this time. Defaults to the animation {@link Animation#duration}. */
    #if !spine_no_inline inline #end public function getAnimationEnd():Float {
        return animationEnd;
    }

    #if !spine_no_inline inline #end public function setAnimationEnd(animationEnd:Float):Void {
        this.animationEnd = animationEnd;
    }

    /** The time in seconds this animation was last applied. Some timelines use this for one-time triggers. Eg, when this
     * animation is applied, event timelines will fire all events between the <code>animationLast</code> time (exclusive) and
     * <code>animationTime</code> (inclusive). Defaults to -1 to ensure triggers on frame 0 happen the first time this animation
     * is applied. */
    #if !spine_no_inline inline #end public function getAnimationLast():Float {
        return animationLast;
    }

    #if !spine_no_inline inline #end public function setAnimationLast(animationLast:Float):Void {
        this.animationLast = animationLast;
        nextAnimationLast = animationLast;
    }

    /** Uses {@link #getTrackTime()} to compute the <code>animationTime</code>, which is between {@link #getAnimationStart()}
     * and {@link #getAnimationEnd()}. When the <code>trackTime</code> is 0, the <code>animationTime</code> is equal to the
     * <code>animationStart</code> time. */
    #if !spine_no_inline inline #end public function getAnimationTime():Float {
        if (loop) {
            var duration:Float = animationEnd - animationStart;
            if (duration == 0) return animationStart;
            return (trackTime % duration) + animationStart;
        }
        return MathUtils.min(trackTime + animationStart, animationEnd);
    }

    /** Multiplier for the delta time when this track entry is updated, causing time for this animation to pass slower or
     * faster. Defaults to 1.
     * <p>
     * Values < 0 are not supported. To play an animation in reverse, use {@link #getReverse()}.
     * <p>
     * {@link #getMixTime()} is not affected by track entry time scale, so {@link #getMixDuration()} may need to be adjusted to
     * match the animation speed.
     * <p>
     * When using {@link AnimationState#addAnimation(int, Animation, boolean, float)} with a <code>delay</code> <= 0, the
     * {@link #getDelay()} is set using the mix duration from the {@link AnimationStateData}, assuming time scale to be 1. If
     * the time scale is not 1, the delay may need to be adjusted.
     * <p>
     * See AnimationState {@link AnimationState#getTimeScale()} for affecting all animations. */
    #if !spine_no_inline inline #end public function getTimeScale():Float {
        return timeScale;
    }

    #if !spine_no_inline inline #end public function setTimeScale(timeScale:Float):Void {
        this.timeScale = timeScale;
    }

    /** The listener for events generated by this track entry, or null.
     * <p>
     * A track entry returned from {@link AnimationState#setAnimation(int, Animation, boolean)} is already the current animation
     * for the track, so the track entry listener {@link AnimationStateListener#start(TrackEntry)} will not be called. */
    #if !spine_no_inline inline #end public function getListener():AnimationStateListener {
        return listener;
    }

    #if !spine_no_inline inline #end public function setListener(listener:AnimationStateListener):Void {
        this.listener = listener;
    }

    /** Values < 1 mix this animation with the skeleton's current pose (usually the pose resulting from lower tracks). Defaults
     * to 1, which overwrites the skeleton's current pose with this animation.
     * <p>
     * Typically track 0 is used to completely pose the skeleton, then alpha is used on higher tracks. It doesn't make sense to
     * use alpha on track 0 if the skeleton pose is from the last frame render. */
    #if !spine_no_inline inline #end public function getAlpha():Float {
        return alpha;
    }

    #if !spine_no_inline inline #end public function setAlpha(alpha:Float):Void {
        this.alpha = alpha;
    }

    /** When the mix percentage ({@link #getMixTime()} / {@link #getMixDuration()}) is less than the
     * <code>eventThreshold</code>, event timelines are applied while this animation is being mixed out. Defaults to 0, so event
     * timelines are not applied while this animation is being mixed out. */
    #if !spine_no_inline inline #end public function getEventThreshold():Float {
        return eventThreshold;
    }

    #if !spine_no_inline inline #end public function setEventThreshold(eventThreshold:Float):Void {
        this.eventThreshold = eventThreshold;
    }

    /** When the mix percentage ({@link #getMixTime()} / {@link #getMixDuration()}) is less than the
     * <code>attachmentThreshold</code>, attachment timelines are applied while this animation is being mixed out. Defaults to
     * 0, so attachment timelines are not applied while this animation is being mixed out. */
    #if !spine_no_inline inline #end public function getAttachmentThreshold():Float {
        return attachmentThreshold;
    }

    #if !spine_no_inline inline #end public function setAttachmentThreshold(attachmentThreshold:Float):Void {
        this.attachmentThreshold = attachmentThreshold;
    }

    /** When the mix percentage ({@link #getMixTime()} / {@link #getMixDuration()}) is less than the
     * <code>drawOrderThreshold</code>, draw order timelines are applied while this animation is being mixed out. Defaults to 0,
     * so draw order timelines are not applied while this animation is being mixed out. */
    #if !spine_no_inline inline #end public function getDrawOrderThreshold():Float {
        return drawOrderThreshold;
    }

    #if !spine_no_inline inline #end public function setDrawOrderThreshold(drawOrderThreshold:Float):Void {
        this.drawOrderThreshold = drawOrderThreshold;
    }

    /** The animation queued to start after this animation, or null if there is none. <code>next</code> makes up a doubly linked
     * list.
     * <p>
     * See {@link AnimationState#clearNext(TrackEntry)} to truncate the list. */
    #if !spine_no_inline inline #end public function getNext():TrackEntry {
        return next;
    }

    /** The animation queued to play before this animation, or null. <code>previous</code> makes up a doubly linked list. */
    #if !spine_no_inline inline #end public function getPrevious():TrackEntry {
        return previous;
    }

    /** Returns true if at least one loop has been completed.
     * <p>
     * See {@link AnimationStateListener#complete(TrackEntry)}. */
    #if !spine_no_inline inline #end public function isComplete():Bool {
        return trackTime >= animationEnd - animationStart;
    }

    /** Seconds from 0 to the {@link #getMixDuration()} when mixing from the previous animation to this animation. May be
     * slightly more than <code>mixDuration</code> when the mix is complete. */
    #if !spine_no_inline inline #end public function getMixTime():Float {
        return mixTime;
    }

    #if !spine_no_inline inline #end public function setMixTime(mixTime:Float):Void {
        this.mixTime = mixTime;
    }

    /** Seconds for mixing from the previous animation to this animation. Defaults to the value provided by AnimationStateData
     * {@link AnimationStateData#getMix(Animation, Animation)} based on the animation before this animation (if any).
     * <p>
     * A mix duration of 0 still mixes out over one frame to provide the track entry being mixed out a chance to revert the
     * properties it was animating.
     * <p>
     * The <code>mixDuration</code> can be set manually rather than use the value from
     * {@link AnimationStateData#getMix(Animation, Animation)}. In that case, the <code>mixDuration</code> can be set for a new
     * track entry only before {@link AnimationState#update(float)} is first called.
     * <p>
     * When using {@link AnimationState#addAnimation(int, Animation, boolean, float)} with a <code>delay</code> <= 0, the
     * {@link #getDelay()} is set using the mix duration from the {@link AnimationStateData}. If <code>mixDuration</code> is set
     * afterward, the delay may need to be adjusted. For example:
     * <code>entry.delay = entry.previous.getTrackComplete() - entry.mixDuration;</code> */
    #if !spine_no_inline inline #end public function getMixDuration():Float {
        return mixDuration;
    }

    #if !spine_no_inline inline #end public function setMixDuration(mixDuration:Float):Void {
        this.mixDuration = mixDuration;
    }

    /** Controls how properties keyed in the animation are mixed with lower tracks. Defaults to {@link MixBlend#replace}.
     * <p>
     * Track entries on track 0 ignore this setting and always use {@link MixBlend#first}.
     * <p>
     * The <code>mixBlend</code> can be set for a new track entry only before {@link AnimationState#apply(Skeleton)} is first
     * called. */
    #if !spine_no_inline inline #end public function getMixBlend():MixBlend {
        return mixBlend;
    }

    #if !spine_no_inline inline #end public function setMixBlend(mixBlend:MixBlend):Void {
        if (mixBlend == 0) throw new IllegalArgumentException("mixBlend cannot be null.");
        this.mixBlend = mixBlend;
    }

    /** The track entry for the previous animation when mixing from the previous animation to this animation, or null if no
     * mixing is currently occuring. When mixing from multiple animations, <code>mixingFrom</code> makes up a linked list. */
    #if !spine_no_inline inline #end public function getMixingFrom():TrackEntry {
        return mixingFrom;
    }

    /** The track entry for the next animation when mixing from this animation to the next animation, or null if no mixing is
     * currently occuring. When mixing to multiple animations, <code>mixingTo</code> makes up a linked list. */
    #if !spine_no_inline inline #end public function getMixingTo():TrackEntry {
        return mixingTo;
    }

    #if !spine_no_inline inline #end public function setHoldPrevious(holdPrevious:Bool):Void {
        this.holdPrevious = holdPrevious;
    }

    /** If true, when mixing from the previous animation to this animation, the previous animation is applied as normal instead
     * of being mixed out.
     * <p>
     * When mixing between animations that key the same property, if a lower track also keys that property then the value will
     * briefly dip toward the lower track value during the mix. This happens because the first animation mixes from 100% to 0%
     * while the second animation mixes from 0% to 100%. Setting <code>holdPrevious</code> to true applies the first animation
     * at 100% during the mix so the lower track value is overwritten. Such dipping does not occur on the lowest track which
     * keys the property, only when a higher track also keys the property.
     * <p>
     * Snapping will occur if <code>holdPrevious</code> is true and this animation does not key all the same properties as the
     * previous animation. */
    #if !spine_no_inline inline #end public function getHoldPrevious():Bool {
        return holdPrevious;
    }

    /** Resets the rotation directions for mixing this entry's rotate timelines. This can be useful to avoid bones rotating the
     * long way around when using {@link #alpha} and starting animations on other tracks.
     * <p>
     * Mixing with {@link MixBlend#replace} involves finding a rotation between two others, which has two possible solutions:
     * the short way or the long way around. The two rotations likely change over time, so which direction is the short or long
     * way also changes. If the short way was always chosen, bones would flip to the other side when that direction became the
     * long way. TrackEntry chooses the short way the first time it is applied and remembers that direction. */
    #if !spine_no_inline inline #end public function resetRotationDirections():Void {
        timelinesRotation.clear();
    }

    #if !spine_no_inline inline #end public function setReverse(reverse:Bool):Void {
        this.reverse = reverse;
    }

    /** If true, the animation will be applied in reverse. Events are not fired when an animation is applied in reverse. */
    #if !spine_no_inline inline #end public function getReverse():Bool {
        return reverse;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return animation == null ? "<none>" : animation.name;
    }

    public function new() {}
}

class EventQueue {
    private var AnimationState_this:AnimationState;
    private var objects:Array<Dynamic> = new Array();
    public var drainDisabled:Bool = false;

    #if !spine_no_inline inline #end public function start(entry:TrackEntry):Void {
        objects.add(EventType.start);
        objects.add(entry);
        AnimationState_this.animationsChanged = true;
    }

    #if !spine_no_inline inline #end public function interrupt(entry:TrackEntry):Void {
        objects.add(EventType.interrupt);
        objects.add(entry);
    }

    #if !spine_no_inline inline #end public function end(entry:TrackEntry):Void {
        objects.add(EventType.end);
        objects.add(entry);
        AnimationState_this.animationsChanged = true;
    }

    #if !spine_no_inline inline #end public function dispose(entry:TrackEntry):Void {
        objects.add(EventType.dispose);
        objects.add(entry);
    }

    #if !spine_no_inline inline #end public function complete(entry:TrackEntry):Void {
        objects.add(EventType.complete);
        objects.add(entry);
    }

    #if !spine_no_inline inline #end public function event(entry:TrackEntry, event:Event):Void {
        objects.add(EventType.event);
        objects.add(entry);
        objects.add(event);
    }

    #if !spine_no_inline inline #end public function drain():Void {
        if (drainDisabled) return; // Not reentrant.
        drainDisabled = true;

        var listenersArray:SnapshotArray<AnimationStateListener> = AnimationState_this.listeners;
        var i:Int = 0; while (i < this.objects.size) {
            var type:EventType = cast objects.get(i);
            var entry:TrackEntry = fastCast(objects.get(i + 1), TrackEntry);
            var listenersCount:Int = listenersArray.size;
            var listeners = listenersArray.begin();
            var _continueAfterSwitch2 = false; while(true) { var _switchCond2 = (type); {
            if (_switchCond2 == spine.EventType.start) {
                if (entry.listener != null) entry.listener.start(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).start(entry); ii++; }
                break;
            } else if (_switchCond2 == spine.EventType.interrupt) {
                if (entry.listener != null) entry.listener.interrupt(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).interrupt(entry); ii++; }
                break;
            } else if (_switchCond2 == spine.EventType.end) {
                if (entry.listener != null) entry.listener.end(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).end(entry); ii++; }
                // Fall through.
                if (entry.listener != null) entry.listener.dispose(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).dispose(entry); ii++; }
                AnimationState_this.trackEntryPool.free(entry);
                break;
            } else if (_switchCond2 == spine.EventType.dispose) {
                if (entry.listener != null) entry.listener.dispose(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).dispose(entry); ii++; }
                AnimationState_this.trackEntryPool.free(entry);
                break;
            } else if (_switchCond2 == spine.EventType.complete) {
                if (entry.listener != null) entry.listener.complete(entry);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).complete(entry); ii++; }
                break;
            } else if (_switchCond2 == spine.EventType.event) {
                var event:Event = fastCast(objects.get(i++ + 2), Event);
                if (entry.listener != null) entry.listener.event(entry, event);
                var ii:Int = 0; while (ii < listenersCount) {
                    (fastCast(listeners[ii], AnimationStateListener)).event(entry, event); ii++; }
                break;
            } } break; }
            listenersArray.end();
        i += 2; }
        clear();

        drainDisabled = false;
    }

    #if !spine_no_inline inline #end public function clear():Void {
        objects.clear();
    }

    public function new() {}
}

@:enum abstract EventType(Int) from Int to Int {
    var start = 0; var interrupt = 1; var end = 2; var dispose = 3; var complete = 4; var event = 5;
}

/** The interface to implement for receiving TrackEntry events. It is always safe to call AnimationState methods when receiving
 * events.
 * <p>
 * See TrackEntry {@link TrackEntry#setListener(AnimationStateListener)} and AnimationState
 * {@link AnimationState#addListener(AnimationStateListener)}. */
interface AnimationStateListener {
    /** Invoked when this entry has been set as the current entry. */
    public function start(entry:TrackEntry):Void;

    /** Invoked when another entry has replaced this entry as the current entry. This entry may continue being applied for
     * mixing. */
    public function interrupt(entry:TrackEntry):Void;

    /** Invoked when this entry is no longer the current entry and will never be applied again. */
    public function end(entry:TrackEntry):Void;

    /** Invoked when this entry will be disposed. This may occur without the entry ever being set as the current entry.
     * References to the entry should not be kept after <code>dispose</code> is called, as it may be destroyed or reused. */
    public function dispose(entry:TrackEntry):Void;

    /** Invoked every time this entry's animation completes a loop. Because this event is trigged in
     * {@link AnimationState#apply(Skeleton)}, any animations set in response to the event won't be applied until the next time
     * the AnimationState is applied. */
    public function complete(entry:TrackEntry):Void;

    /** Invoked when this entry's animation triggers an event. Because this event is trigged in
     * {@link AnimationState#apply(Skeleton)}, any animations set in response to the event won't be applied until the next time
     * the AnimationState is applied. */
    public function event(entry:TrackEntry, event:Event):Void;
}

class AnimationStateAdapter implements AnimationStateListener {
    #if !spine_no_inline inline #end public function start(entry:TrackEntry):Void {
    }

    #if !spine_no_inline inline #end public function interrupt(entry:TrackEntry):Void {
    }

    #if !spine_no_inline inline #end public function end(entry:TrackEntry):Void {
    }

    #if !spine_no_inline inline #end public function dispose(entry:TrackEntry):Void {
    }

    #if !spine_no_inline inline #end public function complete(entry:TrackEntry):Void {
    }

    #if !spine_no_inline inline #end public function event(entry:TrackEntry, event:Event):Void {
    }

    public function new() {}
}

private class TrackEntryPool extends Pool<TrackEntry> {
    override function newObject() {
        return new TrackEntry();
    }
}



class EventType_enum {

    public inline static var start_value = 0;
    public inline static var interrupt_value = 1;
    public inline static var end_value = 2;
    public inline static var dispose_value = 3;
    public inline static var complete_value = 4;
    public inline static var event_value = 5;

    public inline static var start_name = "start";
    public inline static var interrupt_name = "interrupt";
    public inline static var end_name = "end";
    public inline static var dispose_name = "dispose";
    public inline static var complete_name = "complete";
    public inline static var event_name = "event";

    public inline static function valueOf(value:String):EventType {
        return switch (value) {
            case "start": EventType.start;
            case "interrupt": EventType.interrupt;
            case "end": EventType.end;
            case "dispose": EventType.dispose;
            case "complete": EventType.complete;
            case "event": EventType.event;
            default: EventType.start;
        };
    }

}
