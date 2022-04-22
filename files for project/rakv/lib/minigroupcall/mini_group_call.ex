defmodule MiniGroupCall do
  import Opencensus.Trace
  # 1s
  @calldurationtimeout 1_000
  # 1s
  @terminatingtimeout 1_000

  @canceltimer :infinity

  def group_call_request(state, id, ctx) do
    spanCtx = :oc_trace.start_span("executing-the-command", ctx)

    if Map.has_key?(state, id) do
      record = Map.get(state, id)

      case record[:call_state] do
        :terminatting ->
          new_record =
            record
            |> Keyword.update!(:call_state, fn _ -> :transmitting end)

          new_state = Map.replace(state, id, new_record)
          :oc_trace.finish_span(spanCtx)

          {
            new_state,
            :group_call_grant,
            [
              {:timer, {id, :termination_timer}, @canceltimer},
              {:timer, {id, :call_duration_timer}, @calldurationtimeout}
            ]
          }

        _ ->
          :oc_trace.finish_span(spanCtx)

          {state, :id_already_in_use}
      end
    else
      new_record = [
        call_state: :idle
      ]

      new_state = Map.put(state, id, new_record)
      :oc_trace.finish_span(spanCtx)

      {new_state, :resource_allocation_request}
    end
  end

  def resource_update_response(state, id) do
    if !Map.has_key?(state, id) do
      {state, :not_started}
    else
      record = Map.get(state, id)

      case record[:call_state] do
        :idle ->
          new_record =
            record
            |> Keyword.update!(:call_state, fn _ -> :transmitting end)

          new_state = Map.replace(state, id, new_record)

          {
            new_state,
            :group_call_grant,
            [{:timer, {id, :call_duration_timer}, @calldurationtimeout}]
          }

        _ ->
          {state, :error}
      end
    end
  end

  def transmission_started_indication(state, id) do
    if !Map.has_key?(state, id) do
      {state, :not_started}
    else
      record = Map.get(state, id)

      case record[:call_state] do
        :transmitting ->
          {
            state,
            :group_call_grant,
            [{:timer, {id, :call_duration_timer}, @calldurationtimeout}]
          }

        _ ->
          {state, :error}
      end
    end
  end

  def transmission_ceased_indication(state, id) do
    if !Map.has_key?(state, id) do
      {state, :not_started}
    else
      record = Map.get(state, id)

      case record[:call_state] do
        :transmitting ->
          new_record =
            record
            |> Keyword.update!(:call_state, fn _ -> :terminatting end)

          new_state = Map.put(state, id, new_record)

          {new_state, :group_call_termination_indication,
           [
             {:timer, {id, :call_duration_timer}, @canceltimer},
             {:timer, {id, :termination_timer}, @terminatingtimeout}
           ]}

        _ ->
          {state, :error}
      end
    end
  end

  # def call_duration_timer_expires(state, id) do
  #   if !Map.has_key?(state, id) do
  #     {:not_started, state}
  #   else
  #     record = Map.get(state, id)

  #     case record[:call_state] do
  #       :transmitting ->
  #         new_record =
  #           record
  #           |> Keyword.update!(:call_state, fn _ -> :terminatting end)

  #         new_state = Map.put(state, id, new_record)

  #         {new_state, :group_call_termination_indication,
  #          [
  #            {:timer, {id, :call_duration_timer}},
  #            {:timer, {id, :termination_timer}, @calldurationtimeout}
  #          ]}

  #       _ ->
  #         {state, :error}
  #     end
  #   end
  # end

  def group_call_termination_at_endpoint(state, id) do
    if !Map.has_key?(state, id) do
      {state, :not_started}
    else
      record = Map.get(state, id)

      case record[:call_state] do
        :terminatting ->
          new_state = Map.delete(state, id)

          {new_state, :group_call_termination_complete,
           {:timer, {id, :termination_timer}, @canceltimer}}

        _ ->
          {state, :error}
      end
    end
  end

  def group_call_termination_prolong(state, id) do
    if !Map.has_key?(state, id) do
      {state, :not_started}
    else
      record = Map.get(state, id)

      case record[:call_state] do
        :terminatting ->
          {
            state,
            :group_call_termination_indication,
            [{:timer, {id, :termination_timer}, @terminatingtimeout}]
          }

        _ ->
          {state, :error}
      end
    end
  end

  # def termination_timer_expires(state, id) do
  #   if !Map.has_key?(state, id) do
  #     {:not_started, state}
  #   else
  #     record = Map.get(state, id)

  #     case record[:call_state] do
  #       :terminatting ->
  #         new_state = Map.delete(state, id)
  #         {new_state, :group_call_termination_complete}

  #       _ ->
  #         {state, :error}
  #     end
  #   end
  # end
end
