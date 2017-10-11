package spine.support.math;

import spine.support.utils.FloatArray;

class Matrix3 {
	inline static public var M00 = 0;
	inline static public var M01 = 3;
	inline static public var M02 = 6;
	inline static public var M10 = 1;
	inline static public var M11 = 4;
	inline static public var M12 = 7;
	inline static public var M20 = 2;
	inline static public var M21 = 5;
	inline static public var M22 = 8;
	public var val:FloatArray = FloatArray.create(9);
}