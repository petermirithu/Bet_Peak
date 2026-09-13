defmodule BetPeak.Bets.BetNotifier do
  alias BetPeak.Workers.SendMail

  def send_bet_won_email(bet) do
    SendMail.create_mail_job(bet.user.email, "You won a bet!", """
      Hello #{bet.user.first_name},

      Congratulations! You just won a bet.

      Below are the details of your won bet:
      - Match: #{bet.game.home_team.short_form} VS #{bet.game.away_team.short_form}
      - Selection: #{bet.selection}
      - Stake Amount: KES #{bet.stake_amount}
      - Odds at Placement: #{bet.odds_at_placement}
      - Amount won: KES #{bet.potential_payout}

      Thank you for betting with us!

      Warm regards,
      Bet Peak Team
    """)
  end

  def send_bet_lost_email(bet) do
    SendMail.create_mail_job(bet.user.email, "You lost a bet!", """
      Hello #{bet.user.first_name},

      Oooh no! You just lost a bet.

      Below are the details of your lost bet:
      - Match: #{bet.game.home_team.short_form} VS #{bet.game.away_team.short_form}
      - Selection: #{bet.selection}
      - Stake Amount: KES #{bet.stake_amount}
      - Odds at Placement: #{bet.odds_at_placement}
      - Amount lost: KES #{bet.potential_payout}

      Thank you for betting with us!

      Warm regards,
      Bet Peak Team
    """)
  end
end
