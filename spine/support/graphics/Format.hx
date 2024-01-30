package spine.support.graphics;

enum abstract Format(String) from String to String {
	var alpha = "alpha";
	var intensity = "intensity";
	var luminanceAlpha = "luminanceAlpha";
	var rgb565 = "rgb565";
	var rgba4444 = "rgba4444";
	var rgb888 = "rgb888";
	var rgba8888 = "rgba8888";
}
