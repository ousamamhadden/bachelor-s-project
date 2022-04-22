defmodule CoffeeMachines do
  def start(state, id) do
    if Map.has_key?(state, id) do
      {:id_already_in_use, state}
    else
      new_record = [state: :idle, money: 0, coffee: 0]
      new_state = Map.put(state, id, new_record)
      {:started, new_state}
    end
  end

  @spec insert_money(map, any, any) ::
          {:cannot_insert_money_now, map} | {:money_inserted, map} | {:not_started, map}
  def insert_money(state, id, amount) when amount > 0 do
    if !Map.has_key?(state, id) do
      {:not_started, state}
    else
      record = Map.get(state, id)

      case record[:state] do
        :idle ->
          new_record =
            Keyword.update!(record, :money, fn currentmoney -> currentmoney + amount end)

          new_state = Map.put(state, id, new_record)
          {:money_inserted, new_state}

        _ ->
          {:cannot_insert_money_now, state}
      end
    end
  end

  def buy(state, id) do
    if !Map.has_key?(state, id) do
      {:not_started, state}
    else
      record = Map.get(state, id)

      case record[:state] do
        :idle ->
          cond do
            record[:money] >= 10 ->
              new_record =
                record
                |> Keyword.update!(:money, fn current -> current - 10 end)
                |> Keyword.update!(:state, fn _current -> :making_coffee end)
                |> Keyword.update!(:coffee, fn current -> current + 1 end)

              new_state = Map.put(state, id, new_record)
              {:coffee_bought, new_state}

            true ->
              {:not_enough_money, state}
          end

        _ ->
          {:cannot_insert_money_now, state}
      end
    end
  end

  def take(state, id) do
    if !Map.has_key?(state, id) do
      {:not_started, state}
    else
      record = Map.get(state, id)

      case record[:state] do
        :making_coffee ->
          new_record =
            record
            |> Keyword.update!(:state, fn _current -> :idle end)
            |> Keyword.update!(:coffee, fn current -> current - 1 end)

          new_state = Map.put(state, id, new_record)
          {:a_delicious_cup_of_coffee, new_state}

        _ ->
          {:cannot_take_coffe_now, state}
      end
    end
  end

  def turn_off(state, id) do
    if !Map.has_key?(state, id) do
      {:not_started, state}
    else
      record = Map.get(state, id)

      case record[:state] do
        :idle ->
          new_state = Map.delete(state, id)
          {record[:money], new_state}

        _ ->
          {:cannot_turn_off_now, state}
      end
    end
  end
end
