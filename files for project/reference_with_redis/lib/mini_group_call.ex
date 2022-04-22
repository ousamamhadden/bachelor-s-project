defmodule MiniGroupCall do
  alias MiniGroupCall.Redix

  def group_call_request(id) do
    if MiniGroupCall.Redix.command(["EXISTS", id]) == 1 do
      record = MiniGroupCall.Redix.command(["HVALS", id])

      case Enum.at(record, 0) do
        "terminatting" ->
          MiniGroupCall.Redix.command(["HMSET", id, "call_state", "transmitting"])

          {:group_call_grant}

        _ ->
          {:id_already_in_use}
      end
    else
      MiniGroupCall.Redix.command(["HMSET", id, "call_state", "idle"])

      {:resource_allocation_request}
    end
  end

  def resource_update_response(id) do
    # if MiniGroupCall.Redix.command(["EXISTS", id]) != 1 do
    #   {:not_started}
    # else
    #   record = MiniGroupCall.Redix.command(["HVALS", id])

    #   case Enum.at(record, 0) do
    #     "idle" ->
    #       MiniGroupCall.Redix.command(["HMSET", id, "call_state", "transmitting"])
    #       {:group_call_grant}

    #     _ ->
    #       {:error}
    #   end
    # end
    case Application.get_env(:redis_ref, :resource_update_script) do
      nil ->
        {:error}

      script_sha ->
        case MiniGroupCall.Redix.command(["EVALSHA", script_sha, 0, id]) do
          'ERROR' -> {:error}
          res -> {:group_call_grant}
        end
    end
  end

  def transmission_started_indication(id) do
    if MiniGroupCall.Redix.command(["EXISTS", id]) != 1 do
      {:not_started}
    else
      record = MiniGroupCall.Redix.command(["HVALS", id])

      case Enum.at(record, 0) do
        "transmitting" ->
          {:group_call_grant}

        _ ->
          {:error}
      end
    end
  end

  def transmission_ceased_indication(id) do
    if MiniGroupCall.Redix.command(["EXISTS", id]) != 1 do
      {:not_started}
    else
      record = MiniGroupCall.Redix.command(["HVALS", id])

      case Enum.at(record, 0) do
        "transmitting" ->
          MiniGroupCall.Redix.command(["HMSET", id, "call_state", "terminatting"])

          {:group_call_termination_indication}

        _ ->
          {:error}
      end
    end
  end

  def group_call_termination_at_endpoint(id) do
    if MiniGroupCall.Redix.command(["EXISTS", id]) != 1 do
      {:not_started}
    else
      record = MiniGroupCall.Redix.command(["HVALS", id])

      case Enum.at(record, 0) do
        "terminatting" ->
          MiniGroupCall.Redix.command(["DEL", id])
          {:group_call_termination_complete}

        _ ->
          {:error}
      end
    end
  end

  def group_call_termination_prolong(id) do
    if MiniGroupCall.Redix.command(["EXISTS", id]) != 1 do
      {:not_started}
    else
      record = MiniGroupCall.Redix.command(["HVALS", id])

      case Enum.at(record, 0) do
        "terminatting" ->
          {:group_call_termination_indication}

        _ ->
          {:error}
      end
    end
  end
end
