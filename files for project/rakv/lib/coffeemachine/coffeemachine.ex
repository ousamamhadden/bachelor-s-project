defmodule CoffeeMachine do
  def insert_money(state, amount) when amount > 0 do
    case state[:state] do
      :idle ->
        new_state = Keyword.update!(state, :money, fn currentmoney -> currentmoney + amount end)

        {:money_inserted, new_state}

      _ ->
        {:cannot_insert_money_now, state}
    end
  end

  def buy(state) do
    case state[:state] do
      :idle ->
        cond do
          state[:money] >= 10 ->
            new_state =
              state
              |> Keyword.update!(:money, fn current -> current - 10 end)
              |> Keyword.update!(:state, fn _current -> :making_coffee end)
              |> Keyword.update!(:coffee, fn current -> current + 1 end)

            {:coffee_bought, new_state}

          true ->
            {:not_enough_money, state}
        end

      _ ->
        {:cannot_insert_money_now, state}
    end
  end

  def take(state) do
    case state[:state] do
      :making_coffee ->
        new_state =
          state
          |> Keyword.update!(:state, fn _current -> :idle end)
          |> Keyword.update!(:coffee, fn current -> current - 1 end)

        {:a_delicious_cup_of_coffee, new_state}

      _ ->
        {:cannot_take_coffe_now, state}
    end
  end

  def turn_off(state) do
    case state[:state] do
      :idle ->
        IO.puts("allow turn off")
        {:turned_off, state}

      _ ->
        {:cannot_turn_off_now, state}
    end
  end
end
