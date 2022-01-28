# frozen_string_literal: true

# Human player class
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
      return guess if Game::SAVE_ALIAS.include?(guess)

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
