defmodule ExDesk.Support.TicketStateMachineTest do
  use ExDesk.DataCase, async: true

  alias ExDesk.Support.TicketStateMachine

  describe "valid_transition?/2" do
    test "permite open → pending (aguardar resposta)" do
      assert TicketStateMachine.valid_transition?(:open, :pending)
    end

    test "permite pending → open (resposta recebida)" do
      assert TicketStateMachine.valid_transition?(:pending, :open)
    end

    test "permite any → on_hold (pausar)" do
      assert TicketStateMachine.valid_transition?(:open, :on_hold)
      assert TicketStateMachine.valid_transition?(:pending, :on_hold)
    end

    test "permite on_hold → open (retomar)" do
      assert TicketStateMachine.valid_transition?(:on_hold, :open)
    end

    test "permite any → solved (resolver)" do
      assert TicketStateMachine.valid_transition?(:open, :solved)
      assert TicketStateMachine.valid_transition?(:pending, :solved)
      assert TicketStateMachine.valid_transition?(:on_hold, :solved)
    end

    test "permite solved → closed (encerrar)" do
      assert TicketStateMachine.valid_transition?(:solved, :closed)
    end

    test "permite solved → open (reabrir)" do
      assert TicketStateMachine.valid_transition?(:solved, :open)
    end

    test "NÃO permite open → closed diretamente" do
      refute TicketStateMachine.valid_transition?(:open, :closed)
    end

    test "NÃO permite pending → closed diretamente" do
      refute TicketStateMachine.valid_transition?(:pending, :closed)
    end

    test "NÃO permite closed → qualquer status" do
      refute TicketStateMachine.valid_transition?(:closed, :open)
      refute TicketStateMachine.valid_transition?(:closed, :pending)
      refute TicketStateMachine.valid_transition?(:closed, :on_hold)
      refute TicketStateMachine.valid_transition?(:closed, :solved)
    end
  end

  describe "allowed_transitions/1" do
    test "retorna transições permitidas para cada status" do
      assert TicketStateMachine.allowed_transitions(:open) == [:pending, :on_hold, :solved]
      assert TicketStateMachine.allowed_transitions(:pending) == [:open, :on_hold, :solved]
      assert TicketStateMachine.allowed_transitions(:on_hold) == [:open, :pending, :solved]
      assert TicketStateMachine.allowed_transitions(:solved) == [:open, :closed]
      assert TicketStateMachine.allowed_transitions(:closed) == []
    end
  end
end
