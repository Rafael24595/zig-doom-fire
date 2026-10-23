const std = @import("std");

const math = std.math;

const testing = std.testing;

const wind_default = 0;

const min_wind = -5;
const max_wind = 5;

const min_oxygen = -5;
const max_oxygen = 5;

pub const FireState = struct {
    wind: std.atomic.Value(isize) = .init(wind_default),
    oxygen: std.atomic.Value(isize) = .init(0),
    power: std.atomic.Value(bool) = .init(false),

    pub fn mod_wind(self: *@This(), mod: isize) void {
        self.set_wind(self.wind.load(.acquire) + mod);
    }

    inline fn set_wind(self: *@This(), wind: isize) void {
        const wind_fix = math.clamp(wind, min_wind, max_wind);
        self.wind.store(wind_fix, .release);
    }

    pub fn mod_oxygen(self: *@This(), mod: isize) void {
        self.set_oxygen(self.oxygen.load(.acquire) + mod);
    }

    inline fn set_oxygen(self: *@This(), oxygen: isize) void {
        const oxygen_fix = math.clamp(oxygen, min_oxygen, max_oxygen);
        self.oxygen.store(oxygen_fix, .release);
    }

    pub fn request_power(self: *@This()) void {
        self.power.store(true, .release);
    }

    pub fn consume_power(self: *@This()) bool {
        return self.power.swap(false, .acq_rel);
    }
};
