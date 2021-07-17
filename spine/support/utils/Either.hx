package spine.support.utils;

/**
 * Useful to limit a Dynamic function argument's type to the specified
 * type parameters. This does NOT make the use of Dynamic type-safe in
 * any way (the underlying type is still Dynamic and #if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end() checks +
 * casts are necessary).
 */
abstract Either<T1, T2>(Dynamic) from T1 from T2 to T1 to T2 {}