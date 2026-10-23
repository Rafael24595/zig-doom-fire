const std = @import("std");

const kit_color = @import("terminal_kit").color;

pub const Theme = enum {
    ash,
    warm,
    doom,
    blood,
    cool,
    viridis,
    plasma,
    hell_bloom,
    oblivion,
    singularity,
    neon,
    void_fire_x,
    void_fire_y,
    //rainbow,
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
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.2 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.gray_dark), .weight = 0.3 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.gray), .weight = 0.3 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.gray_light), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.05 },
    },
};

pub const ORANGE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.05 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.orange), .weight = 0.45 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.yellow), .weight = 0.35 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.1 },
    },
};

pub const ORANGE_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.12 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.brown), .weight = 0.20 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.orange), .weight = 0.30 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.gold), .weight = 0.23 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.15 },
    },
};

pub const RED_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.brown), .weight = 0.20 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.red), .weight = 0.30 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.coral), .weight = 0.20 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.15 },
    },
};

pub const BLUE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.05 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.navy), .weight = 0.35 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.cyan), .weight = 0.45 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.15 },
    },
};

pub const GREEN_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.1 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_dark), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_medium), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_bright), .weight = 0.2 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.lavender), .weight = 0.10 },
    },
};

pub const GREEN_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.1 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_dark), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_medium), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green_bright), .weight = 0.2 },
    },
};

pub const PINK_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.10 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.12 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.purple), .weight = 0.22 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_pink), .weight = 0.35 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.16 },
    },
};

pub const PURPLE_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.08 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.deep_purple), .weight = 0.22 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.purple), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.violet), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.lavender), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.pale_lavender), .weight = 0.05 },
    },
};

pub const PURPLE_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.1 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.deep_purple), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_purple), .weight = 0.3 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.hot_purple), .weight = 0.2 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.15 },
    },
};

pub const VOID_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.navy), .weight = 0.30 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.purple), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.lavender), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.05 },
    },
};

pub const VOID_2_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.12 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_blue), .weight = 0.28 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_purple), .weight = 0.25 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_pink), .weight = 0.20 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.15 },
    },
};

pub const NEON_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.black), .weight = 0.1 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_blue), .weight = 0.3 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_pink), .weight = 0.3 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.neon_orange), .weight = 0.2 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.white), .weight = 0.1 },
    },
};

pub const RAINBOW_1_THEME = ThemeMeta{
    .colors = &[_]WeightedColor{
        .{ .rgb = kit_color.rgb_of(kit_color.Color.red), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.orange), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.yellow), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.green), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.cyan), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.blue), .weight = 0.15 },
        .{ .rgb = kit_color.rgb_of(kit_color.Color.purple), .weight = 0.1 },
    },
};

pub fn meta_of(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}

pub const ColorManager = struct {
    allocator: std.mem.Allocator,

    table: [][3]u8,

    pub fn init(
        allocator: std.mem.Allocator,
        intensity: usize,
        theme: Theme,
    ) !@This() {
        const colors = meta_of(theme).colors;

        const table = try generate_palette(
            allocator,
            intensity,
            colors,
        );

        return ColorManager{
            .allocator = allocator,
            .table = table,
        };
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.table);
        self.table = undefined;
    }

    pub fn find(self: @This(), i: usize) ?[3]u8 {
        if (i >= self.table.len or i == 0) {
            return null;
        }
        return self.table[i];
    }

    inline fn generate_palette(
        allocator: std.mem.Allocator,
        intensity: usize,
        theme: []const WeightedColor,
    ) ![][3]u8 {
        var palette = try allocator.alloc([3]u8, intensity + 1);
        errdefer allocator.free(palette);

        @memset(palette, .{ 0, 0, 0 });

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

    inline fn generate_accum(allocator: std.mem.Allocator, theme: []const WeightedColor) ![]f32 {
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

    inline fn index_of_accum(accum: []f32, t: f32) usize {
        var idx: usize = 0;
        while (idx < accum.len and t > accum[idx]) {
            idx += 1;
        }
        return idx;
    }

    inline fn lerp_rgb(a: [3]u8, b: [3]u8, t: f32) [3]u8 {
        return .{
            lerp(a[0], b[0], t),
            lerp(a[1], b[1], t),
            lerp(a[2], b[2], t),
        };
    }

    inline fn lerp(a: u8, b: u8, t: f32) u8 {
        const fa: f32 = @floatFromInt(a);
        const fb: f32 = @floatFromInt(b);

        const result = std.math.clamp(fa + t * (fb - fa), 0, 255);
        return @intFromFloat(result);
    }
};

test "ColorManager generates a palette with the requested length" {
    var manager = try ColorManager.init(std.testing.allocator, 8, .ash);
    defer manager.free();

    try std.testing.expectEqual(9, manager.table.len);
}

test "ColorManager reserves index zero" {
    var manager = try ColorManager.init(std.testing.allocator, 8, .ash);
    defer manager.free();

    try std.testing.expect(manager.find(0) == null);
}

test "ColorManager returns null for out-of-range indices" {
    var manager = try ColorManager.init(std.testing.allocator, 8, .ash);
    defer manager.free();

    try std.testing.expect(manager.find(9) == null);
    try std.testing.expect(manager.find(100) == null);
}

test "ColorManager generates the expected grayscale endpoints" {
    var manager = try ColorManager.init(std.testing.allocator, 8, .ash);
    defer manager.free();

    try std.testing.expectEqual(
        [3]u8{ 0, 0, 0 },
        manager.table[1],
    );

    try std.testing.expectEqual(
        [3]u8{ 255, 255, 255 },
        manager.table[8],
    );
}

test "ColorManager intensity one returns the final theme color" {
    var manager = try ColorManager.init(std.testing.allocator, 1, .ash);
    defer manager.free();

    try std.testing.expect(manager.find(0) == null);

    try std.testing.expectEqual(
        [3]u8{ 255, 255, 255 },
        manager.find(1).?,
    );
}

test "ColorManager supports zero intensity" {
    var manager = try ColorManager.init(std.testing.allocator, 0, .ash);
    defer manager.free();

    try std.testing.expectEqual(1, manager.table.len);
    try std.testing.expect(manager.find(0) == null);
}
