pub const Theme = enum {
    classic,
    star,
    arrow,
    plus,
    triangle,
    spark,
    block,
};

pub const ThemeMeta = struct {
    active_char: []const u8,
    inactive_char: []const u8,
    total_bytes: u8,
};

//TODO -> [Improve]: death_char field MUST be a space char (' ') for performance reasons.
const ThemeMap = [_]ThemeMeta{
    .{ .active_char = "#", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "*", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "^", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "+", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "▲", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "✦", .inactive_char = " ", .total_bytes = 1 },
    .{ .active_char = "█", .inactive_char = " ", .total_bytes = 3 },
};

pub fn meta_of(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}
