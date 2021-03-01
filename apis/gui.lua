-- Screen Class
local Screen = {}

Screen.new = function(id, parent, x, y, width, height, background_colour)
    local self = {}
    self.id = id
    self.parent = parent
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.background_colour = background_colour or colours.lightGrey

    self.active = false
    self.window = window.create(self.parent, self.x, self.y, self.width, self.height)

    local components = {}

    function self.draw()
       
        self.window.setBackgroundColour(self.background_colour)
        self.window.clear()

        for id, component in pairs(components) do
            component.draw(self)
        end
    end

    function self.add(component)
        components[component.id] = component
    end

    function self.remove(id)
        components[id] = nil
    end

    function self.get(component_id)
        return components[component_id]
    end

    function self.run()

        self.draw()
        self.active = true
        
        while self.active do
            parallel.waitForAny(
                
                -- Click Listener
                function () 
                    local _, mouse_button, x, y = os.pullEvent("mouse_click")
        
                    -- Loop through buttons
                    for component, component_details in pairs(components) do
                        
                        -- Checks if click is within bounds of button
                        if x >= component_details.x and 
                           x <= component_details.x + component_details.width and
                           y >= component_details.y and
                           y <= component_details.y + component_details.height and
                           component_details.on_click ~= nil then
        
                            -- Create button_click event
                            component_details.on_click(self, x, y)
                            return
                        end
                    end

                    -- No registered listeners
                    self.focus = nil
                    self.draw()
                end,
                
                -- Char Listener
                function ()
                    local _, char = os.pullEvent("char")

                    -- If focused conmponent pass char event to it
                    if self.focus then
                        if components[self.focus].on_char ~= nil then 
                            components[self.focus].on_char(self, char)
                        end
                    else
                        -- Search for always focused component
                        for id, component_details in pairs(components) do
                            if component_details.focusable == false then
                                if components[id].on_char ~= nil then 
                                    components[id].on_char(self, char)
                                end
                                break
                            end
                        end
                    end
                end,
                
                -- Key Listener
                function ()
                    local _, key_code, _ = os.pullEvent("key")
                    local key = keys.getName(key_code)

                    -- If focused conmponent pass char event to it
                    if self.focus then
                        if components[self.focus].on_key ~= nil then 
                            components[self.focus].on_key(self, key_code)
                        end
                    else
                        -- Search for always focused component
                        for id, component_details in pairs(components) do
                            if component_details.focusable == false then
                                if components[id].on_key ~= nil then 
                                    components[id].on_key(self, key_code)
                                end
                                break
                            end
                        end
                    end  
                end,

                -- Stop Screen Listener
                function ()
                    local _, screen = os.pullEvent("stop_screen")
                    if screen == self.id then
                        self.active = false
                    end
                end
            )
        end

        if self.next_screen ~= nil then
            self.next_screen.run()
        end
    end

    function self.pushScreen(next_screen)
        self.active = false
        self.next_screen = next_screen
        next_screen.last_screen = self
        os.queueEvent("stop_screen", self.id)
    end

    function self.popScreen()
        self.active = false
        self.next_screen = self.last_screen
        os.queueEvent("stop_screen", self.id)
    end

    return self
end

-- Label Class
local Label = {}

Label.new = function(id, text, x, y, colour, background_colour)
    local self = {}
    self.id = id
    self.text = text or ""
    self.x = x
    self.y = y
    self.width = string.len(self.text)
    self.height = 1
    self.colour = colour or colours.white
    self.background_colour = background_colour or colours.lightGrey
    
    self.window = nil

    function self.draw(screen)
        
        if self.window then
            self.window.setCursorPos(1, 1)
            self.window.setTextColour(self.colour)
            self.window.setBackgroundColour(self.background_colour)
            self.window.clear()
            self.window.write(self.text)
        else
            self.window = window.create(
                screen.window,
                self.x,
                self.y,
                self.width,
                self.height)

            self.draw(screen)
        end
    end

    return self
end

-- Button Class
local Button = {}

Button.new = function(id, text, on_click, x, y, colour, background_colour, width, height)
    local self = {}
    self.id = id
    self.text = text
    self.on_click = on_click
    self.x = x
    self.y = y
    self.colour = colour or colours.white
    self.background_colour = background_colour or colours.red
    self.width  = width or string.len(self.text)
    self.height = height or 1

    self.window = nil

    function self.draw(screen)
        
        if self.window then
            self.window.setCursorPos(1, 1)
            self.window.setTextColour(self.colour)
            self.window.setBackgroundColour(self.background_colour)
            self.window.clear()
            self.window.write(self.text)
        else
            self.window = window.create(
                screen.window,
                self.x,
                self.y,
                self.width,
                self.height)

            self.draw(screen)
        end
    end

    return self
end

-- Text Box Class
local TextBox = {}

TextBox.new = function(id, initial, x, y, width, focusable, on_text_changed, colour, background_focus_colour, background_colour)
    local self = {}
    self.id = id
    self.text = initial
    self.x = x
    self.y = y
    self.width = width
    self.height = 1
    self.focusable = focusable
    self.on_text_changed = on_text_changed or nil
    self.colour = colour or colours.white
    self.background_focus_colour = background_focus_colour or colours.grey
    self.background_colour = background_colour or colours.black

    self.window = nil

    local display_text = ""
    
    function self.draw(screen)
        
        if self.window then
            self.window.setCursorPos(1, 1)
            self.window.setTextColour(self.colour)

            if focusable == false or screen.focus == self.id then
                self.window.setBackgroundColour(self.background_focus_colour)
            else
                self.window.setBackgroundColour(self.background_colour)
            end

            self.window.clear()

            local text_length = string.len(self.text)

            if text_length > self.width then
                display_text = string.sub(self.text, text_length - self.width + 1, -1)
            else
                display_text = self.text
            end

            self.window.write(display_text)
        else
            self.window = window.create(
                screen.window,
                self.x,
                self.y,
                self.width,
                self.height)

            self.draw(screen)
        end
    end

    function self.on_click(screen)
        screen.focus = self.id
        screen.draw()
    end

    function self.on_char(screen, char)
        self.text = self.text..char
        self.draw(screen)

        if self.on_text_changed then
            self.on_text_changed(screen, self.text)
        end
    end

    function self.on_key(screen, key_code)

        if keys.getName(key_code) == "backspace" then
            self.text = string.sub(self.text, 1, -2)
            self.draw(screen)

            if self.on_text_changed then
                self.on_text_changed(screen, self.text)
            end
        end
    end

    return self
end

-- List Class
local List = {}

List.new = function(id, values, x, y, width, height, on_row_click, colour, background_colour)
    local self = {}
    self.id = id
    self.values = values or {}
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.on_row_click = on_row_click or nil
    self.colour = colour or colours.black
    self.background_colour = background_colour or colours.white

    self.window = nil

    function self.draw(screen)
        
        if self.window then
            self.window.setCursorPos(1, 1)
            self.window.setTextColour(self.colour)
            self.window.setBackgroundColour(self.background_colour)
            self.window.clear()

            for i=1,self.height,1 do
                local value = self.values[i]
                if value then
                    local value_length = string.len(value)
                    if value_length <= self.width then
                        self.window.write(value)
                    else
                        self.window.write(string.sub(value, 1, self.width))
                    end
                else
                    self.window.write(string.rep(" ", self.width))
                end

                local _, y = self.window.getCursorPos()
                self.window.setCursorPos(1, y + 1)
            end
        else
            self.window = window.create(
                screen.window,
                self.x,
                self.y,
                self.width,
                self.height)

            self.draw(screen)
        end
    end

    function self.on_click(screen, x, y)

        -- Get row number from y
        local row_clicked = y - self.y + 1

        -- Check if row has content
        if self.values[row_clicked] then
            
            -- Call on_row_click if defined
            if self.on_row_click then
                self.on_row_click(screen, row_clicked)
            end
        end
    end

    return self
end

return {
	Screen = Screen,
	Label = Label,
	Button = Button,
    TextBox = TextBox,
    List = List
}