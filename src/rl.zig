pub const Color = extern struct {
    pub const red = Color{ .r = 230, .g = 41, .b = 55, .a = 255 };
    pub const blue = Color{ .r = 0, .g = 121, .b = 241, .a = 255 };
    pub const green = Color{ .r = 0, .g = 228, .b = 48, .a = 255 };
    pub const yellow = Color{ .r = 253, .g = 249, .b = 0, .a = 255 };
    pub const purple = Color{ .r = 200, .g = 122, .b = 255, .a = 255 };

    pub fn fromInt(int: u32) Color {
        return Color{
            .r = @truncate(int >> 24),
            .g = @truncate(int >> 16),
            .b = @truncate(int >> 8),
            .a = @truncate(int),
        };
    }

    pub fn toInt(self: @This()) u32 {
        return (@as(u32, self.r) << 24) | (@as(u32, self.g) << 16) | (@as(u32, self.b) << 8) | @as(u32, self.a);
    }

    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn new(x: f32, y: f32) Vector2 {
        return Vector2{ .x = x, .y = y };
    }

    pub const add = vector2Add;
    pub const subtract = vector2Subtract;
    pub const scale = vector2Scale;
    pub const distance = vector2Distance;
    pub const normalize = vector2Normalize;
    pub const length = vector2Length;
    pub const rotate = vector2Rotate;
    pub const angle = vector2Angle;

    pub const zero = Vector2{ .x = 0, .y = 0 };
};

pub const Key = enum(c_int) {
    a = 65,
    d = 68,
    s = 83,
    w = 87,
};

pub const MouseButton = enum(c_int) {
    left = 0,
    right = 1,
    middle = 2,
};

extern "c" fn InitWindow(width: c_int, height: c_int, title: [*:0]const u8) void;
extern "c" fn SetTargetFPS(fps: c_int) void;
extern "c" fn CloseWindow() void;
extern "c" fn WindowShouldClose() bool;
extern "c" fn BeginDrawing() void;
extern "c" fn EndDrawing() void;
extern "c" fn ClearBackground(color: Color) void;
extern "c" fn GetFrameTime() f32;
extern "c" fn GetTime() f64;
extern "c" fn Vector2Scale(vector: Vector2, scale: f32) Vector2;
extern "c" fn Vector2Add(vector1: Vector2, vector2: Vector2) Vector2;
extern "c" fn Vector2Subtract(vector1: Vector2, vector2: Vector2) Vector2;
extern "c" fn Vector2Distance(vector1: Vector2, vector2: Vector2) f32;
extern "c" fn Vector2Normalize(vector: Vector2) Vector2;
extern "c" fn Vector2Length(vector: Vector2) f32;
extern "c" fn Vector2Rotate(vector: Vector2, angle: f32) Vector2;
extern "c" fn Vector2Angle(vector1: Vector2, vector2: Vector2) f32;

// Input
extern "c" fn IsKeyPressed(key: Key) bool;
extern "c" fn IsKeyDown(key: Key) bool;
extern "c" fn IsMouseButtonPressed(button: MouseButton) bool;
extern "c" fn IsMouseButtonDown(button: MouseButton) bool;
extern "c" fn IsMouseButtonReleased(button: MouseButton) bool;
extern "c" fn IsMouseButtonUp(button: MouseButton) bool;
extern "c" fn GetMousePosition() Vector2;

// Drawing Shapes
extern "c" fn DrawCircle(center_x: c_int, center_x: c_int, radius: f32, color: Color) void;
extern "c" fn DrawCircleV(center: Vector2, radius: f32, color: Color) void;
extern "c" fn DrawCircleLines(center_x: c_int, center_x: c_int, radius: f32, color: Color) void;
extern "c" fn DrawLineV(start: Vector2, end: Vector2, color: Color) void;

pub fn initWindow(width: u32, height: u32, title: [*:0]const u8) void {
    InitWindow(@intCast(width), @intCast(height), title);
}

pub fn setTargetFPS(fps: u32) void {
    SetTargetFPS(@intCast(fps));
}

pub fn closeWindow() void {
    CloseWindow();
}

pub fn windowShouldClose() bool {
    return WindowShouldClose();
}

pub fn beginDrawing() void {
    BeginDrawing();
}

pub fn endDrawing() void {
    EndDrawing();
}

pub fn clearBackground(color: Color) void {
    ClearBackground(color);
}

pub const getFrameTime = GetFrameTime;
pub const getTime = GetTime;

// Input
pub const isKeyPressed = IsKeyPressed;
pub const isKeyDown = IsKeyDown;
pub const isMouseButtonUp = IsMouseButtonUp;
pub const isMouseButtonDown = IsMouseButtonDown;
pub const isMouseButtonPressed = IsMouseButtonPressed;
pub const isMouseButtonReleased = IsMouseButtonReleased;
pub const getMousePosition = GetMousePosition;

// Shapes
pub const drawCircle = DrawCircle;
pub const drawCircleV = DrawCircleV;
pub const drawCircleLines = DrawCircleLines;
pub const drawLineV = DrawLineV;

// Math
pub const vector2Add = Vector2Add;
pub const vector2Subtract = Vector2Subtract;
pub const vector2Distance = Vector2Distance;
pub const vector2Scale = Vector2Scale;
pub const vector2Normalize = Vector2Normalize;
pub const vector2Length = Vector2Length;
pub const vector2Rotate = Vector2Rotate;
pub const vector2Angle = Vector2Angle;
