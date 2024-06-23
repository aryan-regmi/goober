const std = @import("std");
const testing = std.testing;

pub const Widget = struct {
    const Self = @This();

    pub const Vtable = struct {
        deinitFn: *const fn (self: *Widget) void,
        showFn: *const fn (self: *Widget) anyerror!void,
        getParentFn: *const fn (self: *Widget) ?*Widget,
        isDisplayedFn: *const fn (self: *Widget) bool,
    };

    component: *anyopaque,
    component_type_name: []const u8,
    vtable: *const Vtable,

    has_children: bool = false,
    children: ?std.ArrayListUnmanaged(Self) = null,
    parent: ?*Self = null,
    name: ?[]const u8,

    pub fn init(name: ?[]const u8, component: *anyopaque, vtable: *const Vtable) Self {
        return Self{
            .component = component,
            .vtable = vtable,
            .component_type_name = @typeName(@TypeOf(component)),
            .name = name,
        };
    }

    pub fn deinit(self: *Self) void {
        return self.vtable.deinitFn(self);
    }

    pub fn show(self: *Self) anyerror!void {
        return self.vtable.showFn(self);
    }

    pub fn getParent(self: *Self) ?*Self {
        return self.vtable.getParentFn(self);
    }

    pub fn isDisplayed(self: *Self) bool {
        return self.vtable.isDisplayedFn(self);
    }

    pub fn isType(self: *const Self, comptime T: type) bool {
        return self.vtable == &T.Vtable;
    }

    pub fn castUnchecked(self: *const Self, comptime T: type) *T {
        return @ptrCast(@alignCast(self.component));
    }

    pub fn cast(self: *const Self, comptime T: type) ?*T {
        if (self.vtable == &T.Vtable) {
            return self.castUnchecked(T);
        }
        return null;
    }
};

test "Create widget" {
    const Custom = struct {
        pub const Vtable = Widget.Vtable{
            .deinitFn = undefined,
            .showFn = undefined,
            .getParentFn = undefined,
            .isDisplayedFn = undefined,
        };
    };

    var custom = Custom{};
    const custom_widget = Widget.init(null, &custom, &Custom.Vtable);

    try testing.expect(custom_widget.isType(Custom));

    const cast = custom_widget.cast(Custom);
    try testing.expectEqual(&custom, cast.?);
}
