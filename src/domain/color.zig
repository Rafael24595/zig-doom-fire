const std = @import("std");

pub const Color = enum {
    White,
    Black,
    Red,
    Green,
    GreenDark,
    GreenMedium,
    GreenBright,
    GreenOlive,
    GreenMoss,
    Blue,
    Yellow,
    Cyan,
    Magenta,
    Orange,
    Purple,
    DeepPurple,
    Violet,
    HotPurple,
    PaleLavender,
    Gray,
    GrayDark,
    GrayLight,
    Pink,
    Brown,
    Aqua,
    Navy,
    Teal,
    NeonPink,
    NeonGreen,
    NeonBlue,
    NeonYellow,
    NeonOrange,
    NeonPurple,
    NeonCyan,
    NeonRed,
    Lavender,
    Lime,
    Coral,
    Gold,
};

const ColorMap = [_][3]u8{
    .{ 255, 255, 255 }, // White
    .{ 0, 0, 0 }, // Black
    .{ 255, 0, 0 }, // Red
    .{ 0, 255, 0 }, // Green
    .{ 0, 128, 0 }, // GreenDark
    .{ 0, 200, 0 }, // GreenMedium
    .{ 128, 255, 128 }, // GreenBright
    .{ 85, 107, 47 }, // GreenOlive (oscuro, terroso)
    .{ 120, 160, 60 }, // GreenMoss (apagado, natural)
    .{ 0, 0, 255 }, // Blue
    .{ 255, 255, 0 }, // Yellow
    .{ 0, 255, 255 }, // Cyan
    .{ 255, 0, 255 }, // Magenta
    .{ 255, 128, 0 }, // Orange
    .{ 128, 0, 128 }, // Purple
    .{ 48, 0, 72 }, // DeepPurple (muy oscuro, casi negro)
    .{ 138, 43, 226 }, // Violet (violet blue)
    .{ 255, 0, 255 }, // HotPurple (similar a magenta intenso)
    .{ 245, 240, 255 }, // PaleLavender (casi blanco con tinte violeta)
    .{ 128, 128, 128 }, // Gray
    .{ 64, 64, 64 }, // GrayDark
    .{ 192, 192, 192 }, // GrayLight
    .{ 255, 192, 203 }, // Pink
    .{ 165, 42, 42 }, // Brown
    .{ 127, 255, 212 }, // Aqua
    .{ 0, 0, 128 }, // Navy
    .{ 0, 128, 128 }, // Teal
    .{ 255, 0, 144 }, // NeonPink
    .{ 57, 255, 20 }, // NeonGreen
    .{ 0, 191, 255 }, // NeonBlue
    .{ 207, 255, 4 }, // NeonYellow
    .{ 255, 95, 31 }, // NeonOrange
    .{ 191, 0, 255 }, // NeonPurple
    .{ 0, 255, 255 }, // NeonCyan
    .{ 255, 16, 83 }, // NeonRed
    .{ 230, 230, 250 }, // Lavender
    .{ 0, 255, 0 }, // Lime
    .{ 255, 127, 80 }, // Coral
    .{ 255, 215, 0 }, // Gold
};

pub fn rgbOf(c: Color) [3]u8 {
    return ColorMap[@intFromEnum(c)];
}

pub const Theme = enum {
    Ash,
    Warm,
    Doom,
    Blood,
    Cool,
    Viridis,
    Plasma,
    HellBloom,
    Oblivion,
    Singularity,
    Neon,
    VoidFireX,
    VoidFireY,
    //Rainbow,
};

pub const ThemeMeta = struct {
    colors: []const WeightedColor,
};

const WeightedColor = struct {
    rgb: [3]u8,
    weight: f32,
};

const ThemeMap = [_]ThemeMeta{
    GRAY_1_THEME,
    ORANGE_1_THEME,
    ORANGE_2_THEME,
    RED_1_THEME,
    BLUE_1_THEME,
    GREEN_1_THEME,
    GREEN_2_THEME,
    PINK_1_THEME,
    PURPLE_1_THEME,
    PURPLE_2_THEME,
    NEON_1_THEME,
    VOID_1_THEME,
    VOID_2_THEME,
    //RAINBOW_1_THEME,
};

pub const GRAY_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.2 },
        .{ .rgb = rgbOf(Color.GrayDark), .weight = 0.3 },
        .{ .rgb = rgbOf(Color.Gray), .weight = 0.3 },
        .{ .rgb = rgbOf(Color.GrayLight), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.05 },
    },
};

pub const ORANGE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.05 },
        .{ .rgb = rgbOf(Color.Orange), .weight = 0.45 },
        .{ .rgb = rgbOf(Color.Yellow), .weight = 0.35 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.1 },
    },
};

pub const ORANGE_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.12 },
        .{ .rgb = rgbOf(Color.Brown), .weight = 0.20 },
        .{ .rgb = rgbOf(Color.Orange), .weight = 0.30 },
        .{ .rgb = rgbOf(Color.Gold), .weight = 0.23 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.15 },
    },
};

pub const RED_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Brown), .weight = 0.20 },
        .{ .rgb = rgbOf(Color.Red), .weight = 0.30 },
        .{ .rgb = rgbOf(Color.Coral), .weight = 0.20 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.15 },
    },
};

pub const BLUE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.05 },
        .{ .rgb = rgbOf(Color.Navy), .weight = 0.35 },
        .{ .rgb = rgbOf(Color.Cyan), .weight = 0.45 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.15 },
    },
};

pub const GREEN_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.1 },
        .{ .rgb = rgbOf(Color.GreenDark), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.GreenMedium), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.GreenBright), .weight = 0.2 },
        .{ .rgb = rgbOf(Color.Lavender), .weight = 0.10 },
    },
};

pub const GREEN_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.1 },
        .{ .rgb = rgbOf(Color.GreenDark), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.GreenMedium), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.GreenBright), .weight = 0.2 },
    },
};

pub const PINK_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.10 },
        .{ .rgb = rgbOf(Color.Black), .weight = 0.12 },
        .{ .rgb = rgbOf(Color.Purple), .weight = 0.22 },
        .{ .rgb = rgbOf(Color.NeonPink), .weight = 0.35 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.16 },
    },
};

pub const PURPLE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.08 },
        .{ .rgb = rgbOf(Color.DeepPurple), .weight = 0.22 },
        .{ .rgb = rgbOf(Color.Purple), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.Violet), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.Lavender), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.PaleLavender), .weight = 0.05 },
    },
};

pub const PURPLE_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.1 },
        .{ .rgb = rgbOf(Color.DeepPurple), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.NeonPurple), .weight = 0.3 },
        .{ .rgb = rgbOf(Color.HotPurple), .weight = 0.2 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.15 },
    },
};

pub const VOID_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.Navy), .weight = 0.30 },
        .{ .rgb = rgbOf(Color.Purple), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.Lavender), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.05 },
    },
};

pub const VOID_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.12 },
        .{ .rgb = rgbOf(Color.NeonBlue), .weight = 0.28 },
        .{ .rgb = rgbOf(Color.NeonPurple), .weight = 0.25 },
        .{ .rgb = rgbOf(Color.NeonPink), .weight = 0.20 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.15 },
    },
};

pub const NEON_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Black), .weight = 0.1 },
        .{ .rgb = rgbOf(Color.NeonBlue), .weight = 0.3 },
        .{ .rgb = rgbOf(Color.NeonPink), .weight = 0.3 },
        .{ .rgb = rgbOf(Color.NeonOrange), .weight = 0.2 },
        .{ .rgb = rgbOf(Color.White), .weight = 0.1 },
    },
};

pub const RAINBOW_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = rgbOf(Color.Red), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Orange), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Yellow), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Green), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Cyan), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Blue), .weight = 0.15 },
        .{ .rgb = rgbOf(Color.Purple), .weight = 0.1 },
    },
};

pub fn metaOf(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}

pub const ColorManager = struct {
    allocator: *std.mem.Allocator,

    table: [][3]u8,

    pub fn init(allocator: *std.mem.Allocator, intensity: usize, theme: Theme) !@This() {
        const colors = metaOf(theme).colors;

        const table = try generate_palette(allocator, intensity, colors);

        return ColorManager{
            .allocator = allocator,
            .table = table,
        };
    }

    pub fn find(self: @This(), i: usize) ?[3]u8 {
        if (i >= self.table.len or i == 0) {
            return null;
        }
        return self.table[i];
    }

    fn generate_palette(
        allocator: *std.mem.Allocator,
        intensity: usize,
        theme: []const WeightedColor,
    ) ![][3]u8 {
        var palette = try allocator.alloc([3]u8, intensity + 1);
        if (theme.len == 0 or intensity == 0) {
            return palette;
        }

        const accum = try generate_accum(allocator, theme);
        defer allocator.free(accum);

        const f_intensity: f32 = @floatFromInt(intensity);
        for (0..intensity + 1) |i| {
            const f_i: f32 = @floatFromInt(i);
            const t = f_i / f_intensity;

            const idx = index_of_accum(accum, t);

            if (idx == 0) {
                palette[i] = theme[0].rgb;
                continue;
            }

            if (idx >= theme.len) {
                palette[i] = theme[theme.len - 1].rgb;
                continue;
            }

            const t0 = accum[idx - 1];
            const t1 = accum[idx];

            const local_t = (t - t0) / (t1 - t0);

            palette[i] = lerp_rgb(
                theme[idx - 1].rgb,
                theme[idx].rgb,
                local_t,
            );
        }

        return palette;
    }

    fn generate_accum(allocator: *std.mem.Allocator, theme: []const WeightedColor) ![]f32 {
        var total: f32 = 0;
        for (theme) |c| {
            total += c.weight;
        }

        var accum = try allocator.alloc(f32, theme.len);

        var running: f32 = 0;
        for (theme, 0..) |c, i| {
            running += c.weight / total;
            accum[i] = running;
        }

        return accum;
    }

    fn index_of_accum(accum: []f32, t: f32) usize {
        var idx: usize = 0;
        while (idx < accum.len and t > accum[idx]) {
            idx += 1;
        }
        return idx;
    }

    fn lerp_rgb(a: [3]u8, b: [3]u8, t: f32) [3]u8 {
        return .{
            lerp(a[0], b[0], t),
            lerp(a[1], b[1], t),
            lerp(a[2], b[2], t),
        };
    }

    fn lerp(a: u8, b: u8, t: f32) u8 {
        const fa: f32 = @floatFromInt(a);
        const fb: f32 = @floatFromInt(b);

        const result = std.math.clamp(fa + t * (fb - fa), 0, 255);
        return @intFromFloat(result);
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.table);
        self.table = null;
    }
};
