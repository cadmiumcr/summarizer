require "./summarizer"

module Cadmium
  module Summarizer
    # An implementation of TextRank algorithm for summarization.
    # Step 1 : Create a stochastic matrix for PageRank.
    # From sumy source code : Element at row i and column j of the matrix corresponds to the similarity of sentence i
    # and j, where the similarity is computed as the number of common words between them, divided
    # by their sum of logarithm of their lengths. After such matrix is created, it is turned into
    # a stochastic matrix by normalizing over columns i.e. making the columns sum to one. TextRank
    # uses PageRank algorithm with damping, so a damping factor is incorporated as explained in
    # TextRank's paper. The resulting matrix is a stochastic matrix ready for power method.
    # Source: https://web.eecs.umich.edu/~mihalcea/papers/mihalcea.emnlp04.pdf
    class TextRank < AbstractSummarizer
      include Apatite
      @damping = 0.85
      @epsilon = 1e-4

      private def power_method(matrix : Matrix, epsilon = @epsilon)
        transposed_matrix = matrix.transpose
        sentences_count = matrix.size
        p_vector = [1.0 / sentences_count] * sentences_count
        lambda_val = 1.0

        while lambda_val > epsilon
          next_p = transposed_matrix.dot(p_vector)
          lambda_val = (next_p - p_vector).norm
          p_vector = next_p
        end

        p_vector
      end

      private def create_matrix(text : String) : Matrix
        sentences_as_significant_terms = Sentence.sentences(text).map { |sentence| significant_terms(sentence) }
        number_of_sentences = sentences_as_significant_terms.size
        weights = Matrix.build(number_of_sentences) { 0.0 }
        sentences_as_significant_terms.each_with_index do |words_i, i|
          sentences_as_significant_terms.each_with_index do |words_j, j|
            weights[i, j] = rate_sentences_edge(words_i, words_j)
          end
        end

        weights /= weights.row_vectors.sum(Vector[0.0]).to_matrix # To be fixed ?

        Matrix.build(number_of_sentences) { (1.0 - @damping) / number_of_sentences } + weights.map { |weight| weight * @damping }
      end

      # See if we can assert that sentence_1.size and sentence_2.size > 0
      private def rate_sentences_edge(sentence_1 : Array(String), sentence_2 : Array(String)) : Float64
        rank = 0

        sentence_1.each do |word_1|
          sentence_2.each do |word_2|
            rank = word_1 == word_2 ? rank + 1 : rank
          end
        end
        return 0.0 if rank = 0

        norm = Math.log(sentence_1.size) + Math.log(sentence_2.size)
        return rank * 1.0 if sentence_1.size + sentence_2.size == 2
        rank / norm
      end

      private def select_sentences(text : String, max_num_sentences : Int) : Array(String)
        matrix = create_matrix(text)
        ranks = power_method(matrix, @epsilon)
        ranked_sentences = Sentence.sentences(text).zip(ranks).sort_by { |sentence_and_rating| sentence_and_rating[1] }
        ranked_sentences...max_num_sentences.map { |sentence_and_rating| sentence_and_rating[0] }
      end
    end
  end
end
