# frozen_string_literal: true

require_relative 'game'

def play_game(game)
  if game.start == 'load'
    game = Game.load

    # If file is found upon loading
    if game.instance_of?(Game)
      play_game(game)
    # If file is not found
    else
      play_game(Game.new)
    end
  end
  repeat_game
end

def repeat_game
  puts "Would you like to play again? Enter 'y' for yes or 'n' for no: "
  gets.chomp.downcase == 'y' ? play_game(Game.new) : exit
end

play_game(Game.new)
