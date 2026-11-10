const std = @import("std");

const terminal_kit = @import("terminal_kit");

const Counter = terminal_kit.frame.Counter;

const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const SplitMix64 = terminal_kit.splitmix64.SplitMix64;

const configuration = @import("../configuration/configuration.zig");

const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const color = @import("../domain/color.zig");

const wind_default = 0;

/// Holds the resources and state required to render the matrix,
/// including its matrix data, output formatter, and frame counter.
///
/// Call `init` before using the context and `deinit` to release its
/// resources after successful initialization.
pub const RenderContext = struct {
    /// Manages color intensity and formatting for the fire matrix.
    color_manager: color.ColorManager,
    /// Matrix containing the data to be rendered.
    matrix: LinearMatrix,
    /// Handles the formatting and output of the matrix.
    matrix_printer: LinearMatrixPrinter,

    /// Tracks the number of frames rendered and calculates the frame rate.
    counter: Counter,

    /// Initializes the rendering resources using the terminal dimensions
    /// and the provided configuration.
    ///
    /// Returns an error if initialization or matrix construction fails.
    pub fn init(
        self: *@This(),
        allocator: std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        state: *RuntimeState,
        printer: *Printer,
        rng: *SplitMix64,
    ) !void {
        const space = calculate_padding(state);

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        const intensity: usize = calculate_intensity(config, rows);

        self.color_manager = try color.ColorManager.init(
            allocator,
            intensity,
            config.theme_color,
        );

        self.matrix = LinearMatrix.init(
            allocator,
            rng,
        );

        errdefer self.matrix.free();

        try self.matrix.build(
            cols,
            rows,
            intensity,
        );

        self.matrix_printer = try LinearMatrixPrinter.init(
            allocator,
            printer,
            self.color_manager,
            config.formatter_matrix,
            config.formatter_cell,
            config.theme_symbol,
            &self.matrix,
        );

        errdefer self.matrix_printer.free();

        self.counter = Counter.init(config.clock);
    }

    /// Releases the resources owned by the rendering context.
    ///
    /// Must be called after successful initialization.
    pub fn deinit(self: *RenderContext) void {
        self.color_manager.free();
        self.matrix.free();
        self.matrix_printer.free();
    }

    /// Switches the fire state in the matrix.
    ///
    /// The exact effect depends on the implementation of `LinearMatrix.switch_fire`.
    pub fn toggle_power(self: *@This()) void {
        self.matrix.switch_fire();
    }
};

inline fn calculate_padding(state: *RuntimeState) usize {
    var space: usize = 0;
    if (state.show_debug()) {
        space += 4;
    }

    if (state.show_controls()) {
        space += 2;
    }

    return space;
}

inline fn calculate_intensity(config: *const configuration.Configuration, rows: usize) usize {
    if (config.intensity > 0) {
        return config.intensity;
    }

    const f_rows: f32 = @floatFromInt(rows);
    return @intFromFloat(f_rows * config.intensity_per);
}

test "calculate_padding returns zero when all options are disabled" {
    var state = RuntimeState{
        .clock = undefined,
        .debug = .init(false),
        .controls = .init(false),
    };

    try std.testing.expectEqual(0, calculate_padding(&state));
}

test "calculate_padding reserves space for debug output" {
    var state = RuntimeState{
        .clock = undefined,
        .debug = .init(true),
        .controls = .init(false),
    };

    try std.testing.expectEqual(4, calculate_padding(&state));
}

test "calculate_padding reserves space for controls" {
    var state = RuntimeState{
        .clock = undefined,
        .debug = .init(false),
        .controls = .init(true),
    };
    try std.testing.expectEqual(2, calculate_padding(&state));
}

test "calculate_padding reserves space for debug output and controls" {
    var state = RuntimeState{
        .clock = undefined,
        .debug = .init(true),
        .controls = .init(true),
    };

    try std.testing.expectEqual(6, calculate_padding(&state));
}

test "calculate_intensity returns the configured intensity when positive" {
    const config = configuration.Configuration{
        .clock = undefined,
        .intensity = 12,
        .intensity_per = 0.5,
    };

    try std.testing.expectEqual(12, calculate_intensity(&config, 20));
}

test "calculate_intensity derives intensity from row count" {
    const config = configuration.Configuration{
        .clock = undefined,
        .intensity = 0,
        .intensity_per = 0.5,
    };

    try std.testing.expectEqual(10, calculate_intensity(&config, 20));
}

test "calculate_intensity returns zero for zero rows" {
    const config = configuration.Configuration{
        .clock = undefined,
        .intensity = 0,
        .intensity_per = 0.5,
    };

    try std.testing.expectEqual(0, calculate_intensity(&config, 0));
}

test "calculate_intensity truncates fractional results" {
    const config = configuration.Configuration{
        .clock = undefined,
        .intensity = 0,
        .intensity_per = 0.35,
    };

    try std.testing.expectEqual(3, calculate_intensity(&config, 10));
}
