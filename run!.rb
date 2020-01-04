require "gosu"

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 450
MAX_PLAYER_Y = 150

# Use to determine which image is in the front and which image is at the back
module ZOrder
    BACKGROUND, MAP, PLAYER, UI = *0..3
end

# Player Class
class Player
    attr_accessor :stand, :walk, :direction, :x, :y, :vx, :vy, :x_radius, :height, :state, :hp

    def initialize y
        @stand = Gosu::Image.new("images/player_stand.png", :tileable => true)
        @walk = Gosu::Image.load_tiles("images/player_walk.png", 64, 64, :tileable => true)
        @x = 200
        @y = y
        @x_radius = 19
        @vx = 3
        @vy = 0
        @height = 64
        @state = :stand
        @hp = 100
    end
end

# Platform Class
class Platform
    attr_accessor :image, :x, :y, :radius

    def initialize (image, x, y)
        @image = Gosu::Image.new("images/#{image}.png", :tileable => true)
        @x = x
        @y = y
        @radius = 32
    end
end

# Coin Class
class Coin 
    attr_accessor :image, :x, :y, :radius

    def initialize(x, y)
        @image = Gosu::Image.new("images/coin.png", :tileable => true)
        @x = x
        @y = y
        @radius = 10
    end
end

# PowerUp Class
class PowerUp
    attr_accessor :image, :x, :y, :radius

    def initialize(x, y)
        @image = Gosu::Image.new("images/power.png", :tileable => true)
        @x = x
        @y = y
        @radius = 20
    end
end

# Monster Class
class Monster
    attr_accessor :image, :x, :y, :radius

    def initialize(image, x, y)
        @image = Gosu::Image.load_tiles("images/#{image}.png", 32, 32, :tileable => true)
        @x = x
        @y = y
        @radius = 16
    end
end

# Bullet Class
class Bullet
    attr_accessor :x, :y, :radius, :image, :direction

    def initialize (x, y, direction)
        @x = x
        @y = y 
        @image = Gosu::Image.new("images/bullet.png")
        @radius = 3
        @direction = direction
    end
end

class GameWindow < Gosu::Window

    # Read in the high score from file
    def read_high_score
        file = File.new("highscore.txt", "r")
        hi_score = file.gets.to_i
        file.close
        return hi_score
    end

    #####  Start Screen #####
    def initialize
        super SCREEN_WIDTH, SCREEN_HEIGHT
        self.caption = "Run! Run! Run!"
        @start_background = Gosu::Image.new("images/start.png", :tileable => true)
        @title = Gosu::Font.new(self, './Hemondalisa.ttf', 100)
        @font = Gosu::Font.new(self, './Bencoleng.otf', 25)
        @play = Gosu::Image.load_tiles("images/play.png", 100, 100, :tileable => true)
        @how = Gosu::Image.load_tiles("images/how.png", 100, 100, :tileable => true)
        @credit = Gosu::Image.load_tiles("images/credit.png", 100, 100, :tileable => true)
        @home = Gosu::Image.load_tiles("images/home.png", 100, 100, :tileable => true)
        @how_screen = Gosu::Image.new("images/how_screen.png", :tileable => true)
        @credit_screen = Gosu::Image.new("images/credit_screen.png", :tileable => true)
        @end_screen = Gosu::Image.new("images/end_screen.png", :tileable => true)
        @scene = :start # Use to determine which update, draw method and button_down to run
        @hi_score = read_high_score
        @song = Gosu::Song.new("audio/ticker.ogg")
        @song.play(true)
    end

    # Show cursor in the screen
    def needs_cursor?; 
        true; 
    end

    ## Other Checking Function ##
    
    # Check whether the mouse is clicked within the area
    def area_clicked(leftX, topY, rightX, bottomY)
        if ((mouse_x > leftX && mouse_x < rightX) && (mouse_y > topY && mouse_y < bottomY))
            true
        else
            false
        end
    end

    ## Checking Mouse and Keyboard Input##
    def button_down_start (id)
        case id
        when Gosu::MS_LEFT
            if area_clicked(230, 220, 330, 320)
                initialize_game
                @scene = :game
            elsif area_clicked(350, 220, 450, 320)
                @scene = :how
            elsif area_clicked(470, 220, 570, 320)
                @scene = :credit
            end
        end
    end

    def button_down_how_and_credit (id)
        case id
        when Gosu::MS_LEFT
            if area_clicked(660, 322, 760, 422)
                @scene = :start
            end
        end
    end

    ## Draw start screen ##

    def draw_button (button, leftX, rightX, topY, bottomY)
        if ((mouse_x > leftX and mouse_x < rightX) and (mouse_y > topY and mouse_y < bottomY))
            button[1].draw(leftX, topY, ZOrder::UI, 1, 1)
        else
            button[0].draw(leftX, topY, ZOrder::UI, 1, 1)
        end
    end

    def draw_start
        @start_background.draw(0, 0, ZOrder::BACKGROUND, 0.5, 0.5)
        @title.draw_text("Run!", 320, 70, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
        @title.draw_text("3", 490, 70, ZOrder::UI , 0.3, 0.3, Gosu::Color::WHITE)
        draw_button(@play, 230, 330, 220, 320)
        draw_button(@how, 350, 450, 220, 320)
        draw_button(@credit, 470, 570, 220, 320)
    end

    # Use to draw basic screen that contains only an image and a button (E.g. Credit and How to Play)
    def draw_screen (screen)
        screen.draw(0, 0, ZOrder::BACKGROUND, 0.5, 0.5)
        draw_button(@home, 660, 760, 322, 422)
    end

    ##### Game Screen #####

    ## Game Checking Function ##
    # Use to check whether the player is on the platform
    def on_platform?
        result = false
        @ground_platforms.each do |ground_platform|
            if ((@player.x >= ground_platform.x - (ground_platform.radius + @player.x_radius)) && 
                (@player.x <= ground_platform.x + (ground_platform.radius + @player.x_radius)) &&
                (@player.y == ground_platform.y - @player.height))
                result = true
            end
        end

        @platforms.each do |platform|
            if ((@player.x >= platform.x - (platform.radius + @player.x_radius)) && 
                (@player.x <= platform.x + (platform.radius + @player.x_radius)) &&
                (@player.y == platform.y - @player.height))
                result = true
            end
        end

        return result
    end

    # Use to check whether the player is blocked by the platform
    def block_by_platform? (move_x, move_y)
        result = false
        @ground_platforms.each do |ground_platform|
            if ((@player.x + move_x >= ground_platform.x - (ground_platform.radius + @player.x_radius))  && 
                (@player.x + move_x <= ground_platform.x + (ground_platform.radius + @player.x_radius)) && 
                (@player.y + move_y > ground_platform.y - @player.height)  && 
                (@player.y + move_y <= ground_platform.y + 2* ground_platform.radius))
                result = true
            end
        end

        @platforms.each do |platform|
            if ((@player.x + move_x >= platform.x - (platform.radius + @player.x_radius))  && 
                (@player.x + move_x <= platform.x + (platform.radius + @player.x_radius)) && 
                (@player.y + move_y > platform.y - @player.height)  && 
                (@player.y + move_y <= platform.y + platform.radius))
                result = true
            end
        end

        return result
    end

    # Use to check for the collison between the player and the item (Coins, powerup and monster)
    def collision? item
        if (Gosu.distance(@player.x, @player.y + @player.height / 2, item.x, item.y + item.radius) < (item.radius + @player.x_radius))
            return true
        else
            return false
        end
    end

    # Use to check whether the bullet collide with the monster
    def defeat_monster?
        result = false
        @monsters.each do |monster|
            @bullets.each do |bullet|
                if (Gosu.distance(bullet.x, bullet.y + bullet.radius, monster.x, monster.y + monster.radius) < (bullet.radius + monster.radius))
                    @bullets.delete bullet
                    @monsters.delete monster
                    result = true
                end
            end
        end
        return result
    end

    # Use to check whether the powerup is collected and random give skills to player
    def power_up_collected?
        @powerups.each do |powerup|
            if (collision?(powerup))
                @powerups.delete powerup
                choice = rand(1..10)
                case choice
                when 1
                    @level += 1
                when 2..4
                    @bullet_amount = 50
                when 5..6
                    @player.vx = 1
                    @timer = Gosu.milliseconds + 5000
                when 7..8
                    @player.vx = 0
                    @timer = Gosu.milliseconds + 2000
                when 9
                    @score += (@coins.length * 5)
                    @coins = []
                when 10
                    @score += (@monsters.length * 10)
                    @monsters = []
                end
            end
        end
    end

    # Use to check whether player is hurt by the monster
    def defeat_by_monster?
        result = false
        @monsters.each do |monster|
            if (collision?(monster))
                result = true
                @monsters.delete monster
            end
        end
        return result
    end

    def game_over?
        result = false
        if @player.x < -32 || @player.y > SCREEN_HEIGHT # Player is out of the left screen
            result = true
        end

        if @player.hp == 0 #Player's HP reach 0%
            result = true
        end

        return result
    end

    ## Game Initialization ##

    def initialize_game
        @background = Gosu::Image.new("images/background.png", :tileable => true)
        @ground_platform_x = 32
        @platform_x = SCREEN_WIDTH + rand(15..60)
        @ground_platforms = Array.new
        @platforms = Array.new
        @coins = Array.new
        @powerups = Array.new
        @monsters = Array.new
        @bullets = Array.new
        @player = Player.new(303)
        @hole = 0
        @level = 0
        @bullet_amount = 30
        @time_pressed = 0
        @score = 0
        @coins_collected = 0
        @monster_defeated = 0
        @timer = 0  #Use for the timing for bad powerups
        @counter = 0 #Use to count frames
        @song = Gosu::Song.new("audio/rushing.ogg")
        @song.play(true)
        setup_initial_map
    end

    ## Map Generation ##

    # Generate platform
    def generate_platform (items, image, x, y)
        items << Platform.new(image, x, y)
    end

    # Generate coins and powerups
    def generate_item (items, item_class, x, y)
        items << item_class.new(x,y)
    end

    # Generate monster
    def generate_monster (x, y)
        choice = rand(1..4)
        case choice
        when 1
            image = "monster1"
        when 2
            image = "monster2"
        when 3
            image = "monster3"
        when 4
            image = "monster4"
        end
        
        @monsters << Monster.new(image, x, y)
    end
    
    # Randomly generate map
    def generate_map
        if (@ground_platforms.length < 15)
            if (rand< 0.6 && @hole < 2)
                generate_platform(@ground_platforms, "f_platform", @ground_platform_x, 386)
                if (rand< 0.9)
                    generate_item(@coins, Coin, @ground_platform_x, 356)
                else
                    if (rand < 0.85)
                        generate_monster(@ground_platform_x, 354)
                    else
                        generate_item(@powerups, PowerUp, @ground_platform_x, 340)
                    end
                end
            else
                @hole += 1
                if (@hole > 2)
                    generate_platform(@ground_platforms, "f_platform", @ground_platform_x, 386)
                    if (rand< 0.9)
                        generate_item(@coins, Coin, @ground_platform_x, 356)
                    else
                        if (rand < 0.85)
                            generate_monster(@ground_platform_x, 354)
                        else
                            generate_item(@powerups, PowerUp, @ground_platform_x, 340)
                        end
                    end
                    @hole = 0
                end
            end
            @ground_platform_x += (64 - @map_velocity)
        else
            @ground_platform_x -= @map_velocity
        end
    
        if (@platforms.length < 15)
            if (rand< 0.3)
                generate_platform(@platforms, "h_platform", @platform_x, 270)
                if (rand< 0.9)
                    generate_item(@coins, Coin, @platform_x, 240)
                else
                    if (rand < 0.85)
                        generate_monster(@platform_x, 238)
                    else
                        generate_item(@powerups, PowerUp, @platform_x, 224)
                    end
                end
            end
            @platform_x += (64 - @map_velocity)
        else
            @platform_x -= @map_velocity
        end
    end

    ## Initial Map Generation ##

    ## Set up the initial map ##
    def setup_initial_map
        index = 0
        while index < 7
            generate_platform(@ground_platforms, "f_platform", @ground_platform_x, 386)
            @ground_platform_x += 64
            index += 1
        end
    end

    ## Check for Keyboard and Mouse Input ##
    def button_down_game (id)
        case id
        when Gosu::KB_UP
            if (@time_pressed < 2 && @player.y > MAX_PLAYER_Y)
                @player.vy = -20
                @time_pressed += 1
            end
        when Gosu::KB_SPACE
            if (@bullet_amount > 0) 
                if @player.direction == :right
                    @bullets << Bullet.new(@player.x + @player.x_radius, @player.y + @player.height / 2, :right)
                    @bullet_amount -= 1
                else
                    @bullets << Bullet.new(@player.x - @player.x_radius, @player.y + @player.height / 2, :left)
                    @bullet_amount -= 1
                end
            end
        end
    end

    ## Game Update ##

    def update_player (player, move_x)
        if move_x == 0
            @player.state = :stand
            player.x -= @map_velocity
        else
            @player.state = :walk
            if (block_by_platform?(move_x, 0))
                player.x -= @map_velocity
            else
                player.x += move_x
            end
            if move_x > 0
                player.direction = :right 
            else
                player.direction = :left
            end 
        end

        if player.vy < 0 && player.vy > -40
            (-player.vy).times do
                if (!block_by_platform?(0, -1))
                    player.y -= 0.5
                else
                    player.vy = 0
                end
            end
        end

        if player.vy > 0
            if player.vy > 20
                down_vy = 20
            else
                down_vy = player.vy 
            end

            player.vy.times do 
                if (!on_platform? || !block_by_platform?(0, 1))
                    player.y += 0.5
                else
                    player.vy = 0
                end
            end
        end

        player.vy += 1
    end

    # Use to move item to the left constanly
    def items_constanly_moving items
        items.each do |item|
            item.x -= @map_velocity
        end
    end

    def calculate_score
        @coins.each do |coin|
            if (collision?(coin))
                @coins.delete coin
                @score += 5
                @coins_collected += 1
            end
        end

        if (defeat_monster?)
            @score += 10
            @monster_defeated += 1
        end

        if @score > @hi_score
            @hi_score = @score
        end
    end

    # Delete Item in the array if the item is no longer on the screen
    def clear_items items
        items.reject! do |item|
            if item.x < -64
                true
            else
                false
            end
        end
    end

    # Delete bullet that is no longer on the screen
    def clear_bullets
        @bullets.reject! do |bullet|
            if bullet.x < -64 || bullet.x > SCREEN_WIDTH + bullet.radius
                true
            else
                false
            end
        end
    end

    # Update Game Details
    def update_game
        # Change the speed of the map according to level
        if (@level < 4)
            @map_velocity = 1 + (@level * 0.5)
        else 
            @map_velocity = 2.5 + ((@level - 3) * 0.2)
        end
        
        generate_map

        #Level up when score reach breakpoint
        if (@level < 3)
            if (@score > (@level + 1) * 100)
                @level += 1
            end
        else 
            if (@score > 300 + ((@level -2) * 300))
                @level += 1
            end
        end

        #Player Movement
        if button_down?(Gosu::KB_RIGHT)
            move_x = @player.vx
        elsif button_down?(Gosu::KB_LEFT)
            move_x = -(@map_velocity + @player.vx)
        else
            move_x = 0
        end
        
        update_player(@player, move_x)

        # Remove the number of times of space pressed every 100 frames
        if @counter == 100
            if @time_pressed > 0
                @time_pressed -= 1
            end
            @counter += 1
        else
            if @counter > 100
                @counter = 0
            end
            @counter += 1
        end

        # Set the number of times of space pressed to 0 when the player is on the platform
        if (on_platform?)
            @time_pressed = 0
        end

        calculate_score
        power_up_collected?
        if (defeat_by_monster?)
            @player.hp -= 20
        end

        if (Gosu.milliseconds > @timer)
            @player.vx = 3
        end

        # Constanly move the item to the left of the screen
        items_constanly_moving(@ground_platforms)
        items_constanly_moving(@platforms)
        items_constanly_moving(@coins)
        items_constanly_moving(@powerups)
        items_constanly_moving(@monsters)

        @bullets.each do |bullet|
            if bullet.direction == :right
                bullet.x += 3
            else
                bullet.x -= (@map_velocity + 3)
            end
        end

        # Delete item that is no longer on the screen
        clear_items(@ground_platforms)
        clear_items(@platforms)
        clear_items(@coins)
        clear_items(@powerups)
        clear_items(@monsters)
        clear_bullets

        # Check whether the game is over
        if (game_over?)
            if (@score == @hi_score)
                file = File.new("highscore.txt", "w")
                file.puts @hi_score
                file.close
            end
            @scene = :end
            @song = Gosu::Song.new("audio/ticker.ogg")
            @song.play(true)
        end
    end

    ## Draw Game Screen ##

    # Draw non-animated and static item (E.g. platform, coin and powerups)
    def draw_static_item (var)
        var.each do |var|
            var.image.draw(var.x - var.radius, var.y, ZOrder::MAP)
        end
    end

    # Draw player
    def draw_player
        if @player.direction == :left
            factor = -1.0
            offset_x = 32
        else
            factor = 1.0
            offset_x = -32
        end

        if (@player.state == :stand)
            @player.stand.draw(@player.x + offset_x,@player.y,ZOrder::PLAYER, factor, 1.0)
        elsif (@player.state == :walk)
            if(Gosu.milliseconds / 175 % 2 == 0)
                @player.walk[0].draw(@player.x + offset_x,@player.y,ZOrder::PLAYER, factor, 1.0)
            else
                @player.walk[1].draw(@player.x + offset_x,@player.y,ZOrder::PLAYER, factor, 1.0)
            end
        end
    end

    # Draw monster
    def draw_monster
        @monsters.each do |monster|
            count = Gosu.milliseconds / 800 % 2
            if(count == 0)
                monster.image[0].draw(monster.x - monster.radius, monster.y,ZOrder::MAP)
            elsif (count == 1)
                monster.image[1].draw(monster.x - monster.radius, monster.y,ZOrder::MAP)
            end
        end
    end

    def display_game_data
        @font.draw_text("HP: #{@player.hp}%", 15, 10, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("Speed: #{@level + 1}", 95, 10, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("Bullet: #{@bullet_amount}", 180, 10, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("Score: #{@score}", 600, 10, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("HI: #{@hi_score}", 710, 10, ZOrder::UI , 1.0, 1.0, Gosu::Color::WHITE)
    end

    def draw_game
        @background.draw(0, 0, ZOrder::BACKGROUND, 0.5, 0.5)
        draw_player
        draw_static_item(@ground_platforms)
        draw_static_item(@platforms)
        draw_static_item(@coins)
        draw_static_item(@powerups)
        draw_static_item(@bullets)
        draw_monster
        display_game_data  
    end

    ##### End Screen #####

    ## Check for Keyboard and Mouse Input ##
    def button_down_end (id)
        case id
        when Gosu::MS_LEFT
            if area_clicked(290, 290, 390, 390)
                initialize_game
                @scene = :game
            elsif area_clicked(410, 290, 510, 390)
                @scene = :start
            end
        end
    end

    ## Draw End Screen ##
    def draw_end
        @end_screen.draw(0, 0, ZOrder::BACKGROUND, 0.5, 0.5)
        @title.draw_text("Game Over", 275, 50, ZOrder::UI , 0.6, 0.6, Gosu::Color::BLACK)
        @font.draw_text("Score: #{@score}", 325, 130, ZOrder::UI , 1.5, 1.5, Gosu::Color::BLACK)
        @font.draw_text("High Score: #{@hi_score}", 269, 170, ZOrder::UI , 1.5, 1.5, Gosu::Color::BLACK)
        @font.draw_text("Coins Collected: #{@coins_collected}", 125, 210, ZOrder::UI , 1.5, 1.5, Gosu::Color::BLACK)
        @font.draw_text("Monster Killed: #{@monster_defeated}", 415, 210, ZOrder::UI , 1.5, 1.5, Gosu::Color::BLACK)

        draw_button(@play, 290, 390, 290, 390)
        draw_button(@home, 410, 510, 290, 390)
    end

    ##### Main Procedure #####

    def update
        case @scene
        when :game
            update_game
        end
    end

    def draw
        case @scene
        when :start
            draw_start
        when :how
            draw_screen(@how_screen)
        when :credit
            draw_screen(@credit_screen)
        when :game
            draw_game
        when :end
            draw_end
        end
    end

    def button_down (id)
        case @scene
        when :start
            button_down_start(id)
        when :how
            button_down_how_and_credit(id)
        when :credit
            button_down_how_and_credit(id)
        when :game
            button_down_game(id)
        when :end
            button_down_end(id)
        end
    end  
end

GameWindow.new.show