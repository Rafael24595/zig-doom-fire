const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;

const Flag = terminal_kit.configuration.Flag;
const kit_conf = terminal_kit.configuration;

const kit_formatter = terminal_kit.formatter;
const kit_color = terminal_kit.color;

const matrix = @import("../domain/matrix.zig");
const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const formatter = @import("../io/formatter.zig");

const frame_pause_ms: u64 = switch (builtin.os.tag) {
    .windows => 45,
    else => 50,
};

const FLAG_HELP: Flag = Flag{
    .flag_short = "-h",
    .flag_long = "--help",
    .desc = "Show this help message",
    .name = "help",
};

const FLAG_VERSION: Flag = Flag{
    .flag_short = "-v",
    .flag_long = "--version",
    .desc = "Show project's version",
    .name = "version",
};

const FLAG_DEBUG: Flag = Flag{
    .flag_short = "-d",
    .flag_long = "",
    .desc = "Enable debug mode",
    .name = "debug",
};

const FLAG_HELP_CONTROLS: Flag = Flag{
    .flag_short = "-hc",
    .desc = "Show the controls map",
    .name = "controls map",
};

const FLAG_SEED: Flag = Flag{
    .flag_short = "-s",
    .type = "<number>",
    .desc = "Random seed",
    .name = "seed",
};

const FLAG_MILLISECONDS: Flag = Flag{
    .flag_short = "-ms",
    .type = "<number>",
    .desc = "Frame delay in ms",
    .name = "milliseconds",
};

const FLAG_INTENSITY: Flag = Flag{
    .flag_short = "-i",
    .type = "<number>",
    .desc = "Intensity",
    .name = "intensity",
};

const FLAG_THEME_COLOR: Flag = Flag{
    .flag_short = "-tc",
    .type = "<enum>",
    .desc = "Theme color",
    .name = "theme color",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_THEME_SYMBOL: Flag = Flag{
    .flag_short = "-ts",
    .type = "<enum>",
    .desc = "Theme symbol",
    .name = "Theme symbol",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_COLOR_MODE: Flag = Flag{
    .flag_short = "-cm",
    .type = "<enum>",
    .desc = "Color mode",
    .name = "color mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

/// Stores the application settings parsed from command-line arguments,
/// including rendering options, animation timing and matrix appearance.
pub const Configuration = struct {
    /// Enables diagnostic information during execution.
    debug: bool = false,
    /// Enables the display of keyboard controls.
    controls: bool = false,

    /// Random seed used to initialize the matrix generation.
    /// A value of zero causes the seed to be derived from the current timestamp.
    seed: u64 = 0,

    /// Application start timestamp, in milliseconds since the Unix epoch.
    start_ms: i64 = 0,

    /// Delay between animation frames, in milliseconds.
    milliseconds: u64 = frame_pause_ms,

    /// Fraction of the matrix height used to derive the default intensity.
    ///
    /// Used only when `intensity` is zero.
    intensity_per: f32 = 0.60,
    /// Explicit matrix intensity.
    ///
    /// A value greater than zero overrides the intensity derived from
    /// `intensity_per` and the matrix height.
    intensity: usize = 0,

    /// Symbol theme used to render the matrix.
    theme_symbol: symbol.Theme = .classic,
    /// Color theme used to render the matrix.
    theme_color: color.Theme = .warm,

    /// Color formatting mode used by the output formatters.
    color_mode: formatter.FormatterCode = .rgb,

    /// Formatter configuration for the matrix output.
    formatter_matrix: kit_formatter.FormatterMatrixUnion = formatter.matrix_union_of(.rgb),
    /// Formatter configuration for individual cells.
    formatter_cell: kit_formatter.FormatterCellUnion = formatter.cell_union_of(.rgb),

    /// Parses command-line arguments into a configuration.
    ///
    /// Uses `allocator` for temporary allocations and `printer` for
    /// formatting or reporting command-line information.
    /// Exits the process for help, version, or unknown arguments.
    pub fn init(
        allocator: std.mem.Allocator,
        printer: *Printer,
        args: [][:0]u8,
    ) !kit_conf.InitResult(Configuration) {
        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, FLAG_HELP.flag_short) or std.mem.eql(u8, arg, FLAG_HELP.flag_long.?)) {
                try print_help(allocator, printer, config);
                return .inf;
            }

            if (std.mem.eql(u8, arg, FLAG_VERSION.flag_short) or std.mem.eql(u8, arg, FLAG_VERSION.flag_long.?)) {
                try printer.printf("\n{any}: {s}\n", .{ build.name, build.version });
                return .inf;
            }

            if (std.mem.eql(u8, arg, FLAG_DEBUG.flag_short)) {
                config.debug = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_HELP_CONTROLS.flag_short)) {
                config.controls = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_SEED.flag_short)) {
                config.seed = try kit_conf.parse_int(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try kit_conf.parse_int(u64, printer, args, i, FLAG_MILLISECONDS, null, 1000 * 3);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INTENSITY.flag_short)) {
                config.intensity = try kit_conf.parse_int(usize, printer, args, i, FLAG_INTENSITY, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_COLOR.flag_short)) {
                config.theme_color = try kit_conf.parse_enum(color.Theme, printer, args, i, FLAG_THEME_COLOR);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_SYMBOL.flag_short)) {
                config.theme_symbol = try kit_conf.parse_enum(symbol.Theme, printer, args, i, FLAG_THEME_SYMBOL);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                config.color_mode = try kit_conf.parse_enum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
                config.formatter_matrix = formatter.matrix_union_of(config.color_mode);
                config.formatter_cell = formatter.cell_union_of(config.color_mode);
                i += 1;
                continue;
            }

            return .{
                .err = try printer.format("\nUnknown argument: {s}\n", .{arg}),
            };
        }

        const timestamp = std.time.milliTimestamp();

        config.start_ms = timestamp;

        if (config.seed == 0) {
            config.seed = @intCast(timestamp);
        }

        return .{ .run = config };
    }

    pub fn print_help(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) !void {
        const message = try format_flags(allocator, printer, config);
        defer allocator.free(message);
        try printer.print(message);
    }

    pub fn format_flags(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) ![]u8 {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 0);

        const intensity_default = try printer.format(
            "{d:.2} x matrix height",
            .{config.intensity_per},
        );

        try buffer.appendSlice(allocator, "\nUsage: zig-doom-fire          [options] \n\n");

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_INTENSITY,
            .{ .str = intensity_default },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_COLOR,
            .{ .str = @tagName(config.theme_color) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_SYMBOL,
            .{ .str = @tagName(config.theme_symbol) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.color_mode) },
        ));

        return buffer.items;
    }
};

/// Builds the application configuration from the current process arguments.
///
/// Allocates the argument list using `allocator` and releases it before
/// returning. Propagates errors from argument allocation and parsing.
pub fn from_args(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    return kit_conf.from_args(
        Configuration,
        allocator,
        printer,
        Configuration.init,
    );
}

test "Configuration uses the expected default values" {
    const config = Configuration{};

    try std.testing.expect(!config.debug);
    try std.testing.expect(!config.controls);

    try std.testing.expectEqual(@as(u64, 0), config.seed);
    try std.testing.expectEqual(@as(i64, 0), config.start_ms);

    try std.testing.expectEqual(frame_pause_ms, config.milliseconds);
    try std.testing.expectEqual(@as(f32, 0.60), config.intensity_per);
    try std.testing.expectEqual(@as(usize, 0), config.intensity);

    try std.testing.expectEqual(symbol.Theme.classic, config.theme_symbol);
    try std.testing.expectEqual(color.Theme.warm, config.theme_color);
    try std.testing.expectEqual(formatter.FormatterCode.rgb, config.color_mode);
}
