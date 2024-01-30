package spine.support.graphics;

enum abstract TextureFilter(String) from String to String {
	var nearest = "nearest";
	var linear = "linear";
	var mipMap = "mipMap";
	var mipMapNearestNearest = "mipMapNearestNearest";
	var mipMapLinearNearest = "mipMapLinearNearest";
	var mipMapNearestLinear = "mipMapNearestLinear";
	var mipMapLinearLinear = "mipMapLinearLinear";
}
