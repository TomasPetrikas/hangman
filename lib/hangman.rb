# frozen_string_literal: true

require_relative 'hangman_ascii'

class Player
  attr_reader :name, :word

  # dictionary must be passed if is_guesser == false
  def initialize(name, dictionary = nil, is_guesser: true)
    @name = name
    @word = generate_word(dictionary) unless is_guesser
  end

  def guess(letters_used)
    loop do
      print "\n#{@name}, enter your guess (a letter or word): "
      guess = gets.chomp.upcase
      # puts ''
      return guess if guess.match?(/^[A-Z]+$/) && !letters_used.include?(guess)

      puts 'Error: you already used that letter' if letters_used.include?(guess)
    end
  end

  private

  def generate_word(dictionary)
    loop do
      print "#{@name}, enter your secret word: "
      word = gets.chomp.upcase
      puts ''
      return word if dictionary.include?(word)

      if word.length.between?(Game::WORD_SIZE_MIN, Game::WORD_SIZE_MAX)
        puts "Error: That's not a word.\n\n"
      else
        puts "Error: The word must be between #{Game::WORD_SIZE_MIN} and #{Game::WORD_SIZE_MAX} characters long.\n\n"
      end
    end
  end
end

class ComputerPlayer < Player
  def initalize(name, dictionary = nil, is_guesser: true)
    super
  end

  private

  def generate_word(dictionary)
    dictionary.sample
  end
end

class Display
  include HangmanASCII

  def intro
    puts "Welcome to Hangman!\n\n"
    rules
    selection
  end

  def clear_screen
    Gem.win_platform? ? (system 'cls') : (system 'clear')
  end

  def try_again
    puts 'Oops, try again:'
  end

  def print_ascii(guesses_left)
    clear_screen

    return if guesses_left == Game::MAX_GUESSES

    puts HANGMAN_PICS[Game::MAX_GUESSES - 1 - guesses_left]
  end

  def print_guesses_left(name, guesses_left)
    puts "#{name} has #{guesses_left} guesses remaining"
  end

  def print_letters_used(letters_used)
    return if letters_used.length.zero?

    puts "Letters used: #{letters_used.join(' ')}"
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
    puts "1 - Guess the computer's word"
    puts '2 - Have the computer guess your word'
  end
end

class Game
  MAX_GUESSES = 10
  WORD_SIZE_MIN = 5
  WORD_SIZE_MAX = 12
  LETTERS = ('A'..'Z').to_a

  def initialize
    @display = Display.new
    @guesses_left = MAX_GUESSES
    @letters_used = []

    dictionary_file = File.open('dictionary.txt', 'r')

    @dictionary = dictionary_file.readlines
    @dictionary.map! { |word| word.chomp.upcase }
    @dictionary.select! { |word| word.length.between?(WORD_SIZE_MIN, WORD_SIZE_MAX) }

    dictionary_file.close

    # p @dictionary.length
    # 10.times do |i|
    #   p @dictionary[i]
    # end
  end

  def start
    @display.clear_screen
    @display.intro
    @game_mode = game_mode

    mode1 if @game_mode == 1
    mode2 if @game_mode == 2
  end

  private

  def game_mode
    loop do
      mode = gets.chomp.to_i
      return mode if [1, 2].include?(mode)

      @display.try_again
    end
  end

  # Guess the computer's word
  def mode1
    @p = Player.new('Player', is_guesser: true)
    @c = ComputerPlayer.new('Computer', @dictionary, is_guesser: false)

    while @guesses_left.positive?
      @display.print_ascii(@guesses_left)
      # display word
      @display.print_guesses_left(@p.name, @guesses_left)
      @display.print_letters_used(@letters_used)
      guess = @p.guess(@letters_used)
      @letters_used << guess if guess.length == 1 && !@letters_used.include?(guess)

      @guesses_left -= 1
    end
  end

  # Computer guesses your word
  def mode2
    @p = Player.new('Player', @dictionary, is_guesser: false)
    @c = ComputerPlayer.new('Computer', is_guesser: true)
  end
end

def play_game
  g = Game.new
  g.start
  # repeat_game
end

def repeat_game
  puts "Would you like to play again? Enter 'y' for yes or 'n' for no: "
  gets.chomp.downcase == 'y' ? play_game : return
end

play_game
