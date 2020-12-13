defmodule NetworkLabWeb.TaskView do
    use NetworkLabWeb, :view

    def username_list_item(username, ideology, extra_class \\ "") do
        name = String.replace(username, "_", " ")
        raw "<li class=\"username #{ ideology } #{ extra_class }\">#{ name }</li>"
    end

    def show_control_instructions?(user) do
        case user.condition_1 do
            "control" -> "block"
            _ -> "none"
        end
    end

    def show_network_instructions?(user) do
        if user.condition_1 == "control" do
            "none"
        else
            case user.network_id do
                nil -> "none"
                _ -> "block"
            end
        end
    end

    def has_neighbours?(user) do
        if Application.get_env(:network_lab, :game_type) == :pretest or user.condition_1 == "control" do
            false
        else
            true
        end
    end

    def regular_time?(user) do
        # current time
        current_time = NaiveDateTime.utc_now()
        # user started at
        user_started = user.started_at
        # what is the time difference in seconds
        elapsed = NaiveDateTime.diff(current_time, user_started, :second)
        # what is the duration of the game
        duration = Application.get_env(:network_lab, :game_duration)

        if elapsed >= duration do
            false
        else
            true
        end
    end

end