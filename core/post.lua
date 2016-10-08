module'aux.post'

include'green_t'
include'aux'
include'aux.util'
include'aux.control'
include'aux.util.color'

local state

function private.process()
	if state.posted < state.count then

		local stacking_complete

		local send_signal, signal_received = signal()
		when(signal_received, function()
			local slot = signal_received()[1]
			if slot then
				return post_auction(slot, process)
			else
				return stop()
			end
		end)

		return aux_stack.start(state.item_key, state.stack_size, send_signal)
	end

	return stop()
end

function private.post_auction(slot, k)
	local item_info = aux_info.container_item(unpack(slot))
	if item_info.item_key == state.item_key and aux_info.auctionable(item_info.tooltip) and item_info.aux_quantity == state.stack_size then

		ClearCursor()
		ClickAuctionSellItemButton()
		ClearCursor()
		PickupContainerItem(unpack(slot))
		ClickAuctionSellItemButton()
		ClearCursor()

		StartAuction(max(1, round(state.unit_start_price * item_info.aux_quantity)), round(state.unit_buyout_price * item_info.aux_quantity), state.duration)

		local send_signal, signal_received = signal()
		when(signal_received, function()
			state.posted = state.posted + 1
			return k()
		end)

		local posted
		event_listener('CHAT_MSG_SYSTEM', function(kill)
			if arg1 == ERR_AUCTION_STARTED then
				send_signal()
				kill()
			end
		end)
	else
		return stop()
	end
end

function public.stop()
	if state then
		kill_thread(state.thread_id)

		local callback = state.callback
		local posted = state.posted

		state = nil

		if callback then
			callback(posted)
		end
	end
end

function public.start(item_key, stack_size, duration, unit_start_price, unit_buyout_price, count, callback)
	stop()
	state = {
		thread_id = thread(process),
		item_key = item_key,
		stack_size = stack_size,
		duration = duration,
		unit_start_price = unit_start_price,
		unit_buyout_price = unit_buyout_price,
		count = count,
		posted = 0,
		callback = callback,
	}
end