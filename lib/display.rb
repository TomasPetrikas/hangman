# frozen_string_literal: true

require_relative 'color'
require_relative 'hangman_ascii'

# Handles most of the screen output
class Display
  include HangmanASCII

  def intro
    puts "Welcome to #{'Hangman'.cyan.bold}!\n\n"
    rules
    selection
  end

  def clear_screen
    Gem.win_platform? ? (system 'cls') : (system 'clear')
  end

  def try_again
    puts 'Oops, try again:'
  end

  def game_saved
    puts 'Your game has been saved.'
    sleep(1)
  end

  def print_game_state(state, player)
    print_tip(state, player)

    clear_screen
    print_ascii(state[:guesses_left])
    print_clue_word(state[:clue_word])
    print_guesses_left(player.name, state[:guesses_left])
    print_letters_used(state[:letters_used])
  end

  # If the word is guessed in time
  def win(winning_player, losing_player)
    puts "\n#{winning_player.name} wins! The secret word was #{losing_player.word}!\n\n"
  end

  # If the guesser runs out of guesses
  def loss(losing_player, winning_player)
    puts "\n#{losing_player.name} loses! The secret word was #{winning_player.word}!\n\n"
  end

  private

  def rules
    puts 'Rules:'
    puts '1. One player thinks of an English word and the other tries to guess it by'
    puts '   suggesting letters.'
    puts '2. If the guesser gets a letter wrong (one not contained in the secret word),'
    puts '   they lose a guess.'
    puts "3. The guesser can have up to #{Game::MAX_GUESSES} wrong guesses before they lose."
    puts '4. The guesser is also allowed to guess the entire word, but they lose a guess'
    puts "   if they get it wrong.\n\n"
  end

  def selection
    puts 'Please make a selection:'
    puts "#{'1'.cyan.bold} - Guess the computer's word"
    puts "#{'2'.cyan.bold} - Have the computer guess your word"
    puts "#{'3'.cyan.bold} - Load a previous save"
    puts "#{'4'.cyan.bold} - Quit"
  end

  def print_tip(state, player)
    # Do nothing unless human player's first turn
    return unless player.instance_of?(Player) && state[:turn].zero?

    clear_screen
    puts "Tip: You can save the game by typing #{Game::SAVE_ALIAS[0].downcase.cyan.bold}"\
    " or #{Game::SAVE_ALIAS[1].downcase.cyan.bold}."
    sleep(3)
  end

  def print_ascii(guesses_left)
    puts HANGMAN_PICS[Game::MAX_GUESSES - guesses_left]
  end

  def print_clue_word(clue_word)
    puts "\n#{clue_word.gsub(//, ' ').strip}"
  end

  def print_guesses_left(name, guesses_left)
    puts "#{name} has #{guesses_left.to_s.cyan.bold} guesses remaining"
  end

  def print_letters_used(letters_used)
    return if letters_used.length.zero?

    puts "Letters used: #{letters_used.join(' ').red.bold}"
  end
end
