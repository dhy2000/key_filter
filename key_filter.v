// 按键消抖模块
module key_filter # (
    parameter KEEP_CYCLES = 32'd1_000_000
) (
    input wire clk,
    input wire rst,
    input wire key,         // 外部按键输入
    output wire idle,       // 是否松开, 高电平有效
    output wire down,       // 是否按下, 高电平有效
    output reg upedge,      // 高电平表示按键被松开, 只维持一个周期有效
    output reg downedge     // 高电平表示按键被按下, 只维持一个周期有效
);

    // 按键电平, 本例中高电平为松开, 低电平为按下
    localparam KEY_IDLE = 1'b1;
    localparam KEY_PRESS = 1'b0;

    // 按键状态
    localparam IDLE = 3'd0;         // 松开
    localparam DOWN = 3'd1;         // 按下
    localparam PRESSING = 3'd2;     // IDLE -> DOWN
    localparam RELEASING = 3'd3;    // DOWN -> IDLE

    reg [3:0] state;
    reg [31:0] divider_cnt;

    always @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
            divider_cnt <= 0;
            upedge <= 0;
            downedge <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    upedge <= 0;
                    downedge <= 0;
                    if (key == KEY_PRESS) begin // 检测到按下, 进入消抖状态, 启动计数器
                        state <= PRESSING;
                        divider_cnt <= 0;
                    end
                end
                PRESSING: begin
                    if (divider_cnt == KEEP_CYCLES - 1) begin
                        // 再次采样按键状态
                        if (key == KEY_PRESS) begin
                            state <= DOWN;
                            divider_cnt <= 0;
                            downedge <= 1;
                        end else begin
                            state <= IDLE;
                            divider_cnt <= 0;
                        end
                    end else begin
                        divider_cnt <= divider_cnt + 1;
                    end
                end
                DOWN: begin
                    upedge <= 0;
                    downedge <= 0;
                    if (key == KEY_IDLE) begin
                        state <= RELEASING;
                        divider_cnt <= 0;
                    end
                end
                RELEASING: begin
                    if (divider_cnt <= KEEP_CYCLES - 1) begin
                        if (key == KEY_IDLE) begin
                            state <= IDLE;
                            divider_cnt <= 0;
                            upedge <= 1;
                        end else begin
                            state <= DOWN;
                            divider_cnt <= 0;
                        end
                    end else begin
                        divider_cnt <= divider_cnt + 1;
                    end
                end
            endcase            
        end
    end

    assign idle = (state == IDLE);
    assign down = (state == DOWN);

endmodule