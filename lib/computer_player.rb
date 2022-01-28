# frozen_string_literal: true

require_relative 'player'

# Computer player class
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
