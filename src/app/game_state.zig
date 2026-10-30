const std = @import("std");

const math = std.math;

const testing = std.testing;

const wind_default = 0;

const min_wind = -5;
const max_wind = 5;

const min_oxygen = -5;
const max_oxygen = 5;

/// Stores the shared state of a fire, including wind intensity,
/// oxygen level, and pending power requests.
///
/// Wind and oxygen values are stored atomically and clamped to
/// their respective ranges when modified through the provided methods.
/// Power requests are represented as a boolean flag that can be
/// requested and consumed atomically.
pub const GameState = struct {
    /// Current wind intensity, initialized to zero.
    /// Values are intended to remain within the range [-5, 5].
    wind: std.atomic.Value(isize) = .init(wind_default),
    /// Current oxygen level, initialized to zero.
    /// Values are intended to remain within the range [-5, 5].
    oxygen: std.atomic.Value(isize) = .init(0),
    /// Indicates whether a power request is pending.
    /// Initialized to false.
    power: std.atomic.Value(bool) = .init(false),

    /// Adjusts the current wind intensity by `mod`.
    ///
    /// The resulting value is clamped to the range [-5, 5].
    pub fn mod_wind(self: *@This(), mod: isize) void {
        self.set_wind(self.wind.load(.acquire) + mod);
    }

    inline fn set_wind(self: *@This(), wind: isize) void {
        const wind_fix = math.clamp(wind, min_wind, max_wind);
        self.wind.store(wind_fix, .release);
    }

    /// Adjusts the current oxygen level by `mod`.
    ///
    /// The resulting value is clamped to the range [-5, 5].
    pub fn mod_oxygen(self: *@This(), mod: isize) void {
        self.set_oxygen(self.oxygen.load(.acquire) + mod);
    }

    inline fn set_oxygen(self: *@This(), oxygen: isize) void {
        const oxygen_fix = math.clamp(oxygen, min_oxygen, max_oxygen);
        self.oxygen.store(oxygen_fix, .release);
    }

    /// Sets the pending power request flag to true.
    pub fn request_power(self: *@This()) void {
        self.power.store(true, .release);
    }

    /// Returns whether a power request was pending and clears the flag.
    ///
    /// Returns `true` if a request was pending; otherwise, returns `false`.
    pub fn consume_power(self: *@This()) bool {
        return self.power.swap(false, .acq_rel);
    }
};

test "FireState initializes with default values" {
    var state = GameState{};

    try testing.expectEqual(0, state.wind.load(.acquire));
    try testing.expectEqual(0, state.oxygen.load(.acquire));
    try testing.expectEqual(false, state.power.load(.acquire));
}

test "wind modifications stay within supported bounds" {
    var state = GameState{};

    state.mod_wind(3);
    try testing.expectEqual(3, state.wind.load(.acquire));

    state.mod_wind(10);
    try testing.expectEqual(5, state.wind.load(.acquire));

    state.mod_wind(-20);
    try testing.expectEqual(-5, state.wind.load(.acquire));
}

test "oxygen modifications stay within supported bounds" {
    var state = GameState{};

    state.mod_oxygen(3);
    try testing.expectEqual(3, state.oxygen.load(.acquire));

    state.mod_oxygen(10);
    try testing.expectEqual(5, state.oxygen.load(.acquire));

    state.mod_oxygen(-20);
    try testing.expectEqual(-5, state.oxygen.load(.acquire));

    try testing.expectEqual(0, state.wind.load(.acquire));
}

test "power requests can be consumed only once" {
    var state = GameState{};

    try testing.expect(!state.consume_power());

    state.request_power();

    try testing.expect(state.consume_power());
    try testing.expect(!state.consume_power());
}

test "repeated power requests remain pending" {
    var state = GameState{};

    state.request_power();
    state.request_power();

    try testing.expect(state.consume_power());
    try testing.expect(!state.consume_power());
}
