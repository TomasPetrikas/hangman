# frozen_string_literal: true

require 'yaml'

require_relative 'computer_player'
require_relative 'display'
require_relative 'player'

# Class of the game itself
class Game
  attr_reader :dictionary

  MAX_GUESSES = 10
  WORD_SIZE_MIN = 5
  WORD_SIZE_MAX = 12
  LETTERS = ('A'..'Z').to_a

  PATH_DICTIONARY = "#{File.dirname(__FILE__)}/../dictionary.txt"
  PATH_SAVE = "#{File.dirname(__FILE__)}/../save_data.yml"

  SAVE_ALIAS = ['/SAVE', '/S'].freeze

  def initialize
    @display = Display.new
    init_game_state

    dictionary_file = File.open(PATH_DICTIONARY, 'r')

    @dictionary = dictionary_file.readlines
    @dictionary.map! { |word| word.chomp.upcase }
    @dictionary.select! { |word| word.length.between?(WORD_SIZE_MIN, WORD_SIZE_MAX) }

    dictionary_file.close

    # p @dictionary.length
    # 10.times do |i|
    #   p @dictionary[i]
    # end
  end

  # @state is a hash meant to contain 5 things:
  #
  # 1. [:guesses_left] - an integer
  # 2. [:turn] - an integer
  # 3. [:letters_available] - an array
  # 4. [:letters_used] - an array
  # 5. [:clue_word] - a string (this comes a bit later)
  #
  # This should probably be its own class, but oh well
  def init_game_state
    @state = {}
    @state[:guesses_left] = MAX_GUESSES
    @state[:turn] = 0
    @state[:letters_available] = LETTERS
    @state[:letters_used] = []
  end

  def start
    # Check if we just loaded from a save
    unless defined?(@p).nil?
      play(@p, @c)
      return
    end

    # Continue if not
    @display.clear_screen
    @display.intro
    @mode = mode

    mode1 if @mode == 1
    mode2 if @mode == 2
    return 'load' if @mode == 3

    exit if @mode == 4
  end

  def save
    File.open(PATH_SAVE, 'w') { |f| f.write(to_yaml) }
  end

  def self.load
    if File.exist?(PATH_SAVE)
      YAML.load(File.read(PATH_SAVE))
    else
      puts 'File not found.'
      sleep(1)
    end
  end

  private

  def mode
    loop do
      choice = gets.chomp.to_i
      return choice if (1..4).to_a.include?(choice)

      @display.try_again
    end
  end

  def update_state(guess_word, secret_word)
    @state[:turn] += 1
    clue_updated = false
    if guess_word.length == 1 && !@state[:letters_used].include?(guess_word)
      @state[:letters_used] << guess_word
      @state[:letters_available] -= [guess_word]

      previous_clue_word = @state[:clue_word].clone
      @state[:clue_word] = update_clue(secret_word)
      clue_updated = true if previous_clue_word != @state[:clue_word]
    end

    @state[:guesses_left] -= 1 unless clue_updated || guess_word == secret_word
  end

  def update_clue(secret_word)
    return '_' * secret_word.length if @state[:letters_used].empty?

    result = ''
    secret_word.split('').each do |char|
      result += if @state[:letters_used].include?(char)
                  char
                else
                  '_'
                end
    end

    result
  end

  # Guess the computer's word
  def mode1
    @p = Player.new('Player', is_guesser: true)
    @c = ComputerPlayer.new('Computer', @dictionary, is_guesser: false)

    @state[:clue_word] = update_clue(@c.word)

    play(@p, @c)
  end

  # Computer guesses your word
  def mode2
    @p = Player.new('Player', @dictionary, is_guesser: false)
    @c = ComputerPlayer.new('Computer', @dictionary, is_guesser: true)

    @state[:clue_word] = update_clue(@p.word)

    play(@c, @p)
  end

  # player1 is guesser, player2 is the one being guessed
  def play(player1, player2)
    while @state[:guesses_left].positive?
      @display.print_game_state(@state, player1)
      # p player2.word
      guess = player1.guess(@state)

      if SAVE_ALIAS.include?(guess)
        save
        @display.game_saved
      else
        update_state(guess, player2.word)
      end

      sleep(1) if player1.instance_of?(ComputerPlayer)

      next if @state[:clue_word] != player2.word && guess != player2.word

      @state[:clue_word] = player2.word
      @display.print_game_state(@state, player1)
      @display.win(player1, player2)
      return
    end

    @display.print_game_state(@state, player1)
    @display.loss(player1, player2)
  end
end
