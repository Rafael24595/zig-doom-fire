/// Available character themes for rendering the fire effect.
pub const Theme = enum {
    classic,
    star,
    arrow,
    plus,
    triangle,
    spark,
    block,
};

/// Defines the characters and byte width used to render a theme.
pub const ThemeMeta = struct {
    /// Character used to represent an active cell.
    active_char: []const u8,
    /// Character used to represent an inactive cell.
    ///
    /// A single-byte space is recommended for efficient rendering.
    inactive_char: []const u8,
    /// UTF-8 byte length of the active character.
    ///
    /// This value must match `active_char.len`.
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

/// Returns the rendering metadata associated with `theme`.
pub fn meta_of(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}
