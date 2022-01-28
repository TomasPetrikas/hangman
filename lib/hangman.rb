# frozen_string_literal: true

require_relative 'hangman_ascii'

require 'yaml'

class Player
  attr_reader :name, :word

  # dictionary must be passed if is_guesser == false
  def initialize(name, dictionary = nil, is_guesser: true)
    @name = name
    @word = generate_word(dictionary) unless is_guesser
  end

  def guess(state)
    loop do
      print "\n#{@name}, enter your guess (a letter or word): "
      guess = gets.chomp.upcase
      return guess if guess.match?(/^[A-Z]+$/) && !state[:letters_used].include?(guess)
      return guess if ['/SAVE', '/S'].include?(guess)

      puts 'Error: you already used that letter' if state[:letters_used].include?(guess)
      puts "Error: that's not a letter or word" unless guess.match?(/^[A-Z]+$/)
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
        puts "Error: The word must be between #{Game::WORD_SIZE_MIN} and"\
        " #{Game::WORD_SIZE_MAX} characters long.\n\n"
      end
    end
  end
end

class ComputerPlayer < Player
  # https://en.wikipedia.org/wiki/Letter_frequency
  # This is specifically for dictionaries, not general English text
  LETTERS_BY_FREQUENCY = 'ESIARNTOLCDUGPMKHBYFVWZXQJ'

  def initialize(name, dictionary, is_guesser: true)
    super
    @possible_words = dictionary if is_guesser
  end

  # Computer player will never guess a whole word, it's technically just a
  # time saver for humans
  def guess(state)
    trim_possible_words(state[:clue_word])
    # p @possible_words.length
    # return @possible_words.first if @possible_words.length == 1

    if @possible_words.length <= 100
      possible_letters = []

      @possible_words.each do |word|
        word.split('').each do |char|
          possible_letters << char unless possible_letters.include?(char)
        end
      end

      possible_letters = possible_letters.intersection(state[:letters_available])
      # p possible_letters

      LETTERS_BY_FREQUENCY.split('').each do |char|
        return char if possible_letters.include?(char)
      end
    else
      LETTERS_BY_FREQUENCY.split('').each do |char|
        return char if state[:letters_available].include?(char)
      end
    end
  end

  private

  def generate_word(dictionary)
    dictionary.sample
  end

  def trim_possible_words(clue_word)
    @possible_words.select! do |word|
      keep_word = true
      keep_word = false if word.length != clue_word.length

      clue_word.split('').each_with_index do |char, i|
        keep_word = false unless char == word[i] || char == '_'
      end

      keep_word
    end
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
    puts "1 - Guess the computer's word"
    puts '2 - Have the computer guess your word'
    puts '3 - Load a previous save'
    puts '4 - Quit'
  end

  def print_tip(state, player)
    # Do nothing unless human player's first turn
    return unless player.instance_of?(Player) && state[:turn].zero?
    
    clear_screen
    puts 'Tip: You can save the game by typing /save or /s.'
    sleep(3)
  end

  def print_ascii(guesses_left)
    puts HANGMAN_PICS[Game::MAX_GUESSES - guesses_left]
  end

  def print_clue_word(clue_word)
    puts "\n#{clue_word.gsub(//, ' ').strip}"
  end

  def print_guesses_left(name, guesses_left)
    puts "#{name} has #{guesses_left} guesses remaining"
  end

  def print_letters_used(letters_used)
    return if letters_used.length.zero?

    puts "Letters used: #{letters_used.join(' ')}"
  end
end

class Game
  attr_reader :dictionary

  MAX_GUESSES = 10
  WORD_SIZE_MIN = 5
  WORD_SIZE_MAX = 12
  LETTERS = ('A'..'Z').to_a

  def initialize
    @display = Display.new
    init_game_state

    dictionary_file = File.open("#{File.dirname(__FILE__)}/../dictionary.txt", 'r')

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
    File.open("#{File.dirname(__FILE__)}/../save_data.yml", 'w') { |f| f.write(to_yaml) }
  end

  def self.load
    if File.exist?("#{File.dirname(__FILE__)}/../save_data.yml")
      YAML.load(File.read("#{File.dirname(__FILE__)}/../save_data.yml"))
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

  # p1 is guesser, p2 is the one being guessed
  def play(p1, p2)
    while @state[:guesses_left].positive?
      @display.print_game_state(@state, p1)
      # p p2.word
      guess = p1.guess(@state)

      if ['/SAVE', '/S'].include?(guess)
        save
        @display.game_saved
      else
        update_state(guess, p2.word)
      end

      sleep(1) if p1.instance_of?(ComputerPlayer)

      next if @state[:clue_word] != p2.word && guess != p2.word

      @state[:clue_word] = p2.word
      @display.print_game_state(@state, p1)
      @display.win(p1, p2)
      return
    end

    @display.print_game_state(@state, p1)
    @display.loss(p1, p2)
  end
end

def play_game(g)
  if g.start == 'load'
    g = Game.load

    # If file is found upon loading
    if g.instance_of?(Game)
      play_game(g)
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
