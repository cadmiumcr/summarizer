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
      @damping = 0.85
      @epsilon = 1e-4
      @delta = 1e-7
      @number_of_sentences : Int32 = 1

      private def power_method(matrix : Tensor(Float64, CPU(Float64)), epsilon = @epsilon) : Tensor(Float64, CPU(Float64))
        # For column-stochastic matrix, use M^T * p for power iteration
        transposed_matrix = matrix.transpose
        p_vector = [1.0 / @number_of_sentences.to_f] * @number_of_sentences
        p_vector = p_vector.to_tensor
        lambda_val : Float64 = 1.0
        while lambda_val > epsilon
          # Power iteration: p = M^T * p (transpose since matrix is column-stochastic)
          # Reshape p_vector to column vector for matmul
          p_col = p_vector.reshape([@number_of_sentences, 1])
          next_p_col = transposed_matrix.matmul(p_col)
          next_p = next_p_col.reshape([@number_of_sentences])
          # Calculate L2 norm manually for 1D tensor
          diff = next_p - p_vector
          lambda_val = Math.sqrt((diff * diff).sum)
          p_vector = next_p
        end

        p_vector.map { |element| element.to_f }
      end

      private def create_matrix(text : String) : Tensor(Float64, CPU(Float64))
        sentences_as_significant_terms = Document.new(text).sentences.map { |sentence| significant_terms(sentence.verbatim) }
        @number_of_sentences = sentences_as_significant_terms.size
        weights = Tensor.new([@number_of_sentences, @number_of_sentences]) { 0.0 }

        sentences_as_significant_terms.each_with_index do |words_i, i|
          sentences_as_significant_terms[i..].each_with_index do |words_j, j|
            weight = rate_sentences_edge(words_i, words_j)
            weights[i, j + i] = weight
            weights[j + i, i] = weight
          end
        end

        #        less efficient algorithm kept for reference purposes
        # sentences_as_significant_terms.each_with_index do |words_i, i|
        #   sentences_as_significant_terms.each_with_index do |words_j, j|
        #     weights[i, j] = rate_sentences_edge(words_i, words_j)
        #   end
        # end

        # Normalize columns and apply damping
        normalized_cols = Tensor.new([@number_of_sentences, @number_of_sentences]) { 0.0 }
        weights.shape[1].times do |i|
          col = weights[..., i]
          # For PageRank, normalize by column sum (not L2 norm) to get stochastic matrix
          col_sum = col.sum
          if col_sum > 0.0
            col_norm = col / col_sum
          else
            # Keep column as-is if sum is zero (all zeros)
            col_norm = col
          end
          normalized_cols[..., i] = col_norm
        end
        damping_matrix = Tensor.new([@number_of_sentences, @number_of_sentences]) { (1.0 - @damping) / @number_of_sentences }
        damping_matrix + normalized_cols * @damping
      end

      # See if we can assert that sentence_1.size and sentence_2.size > 0
      private def rate_sentences_edge(sentence_1 : Array(String), sentence_2 : Array(String)) : Float64
        rank = 0
        return 0.0 if sentence_1 === sentence_2
        sentence_1.each do |word_1|
          sentence_2.each do |word_2|
            rank = word_1 == word_2 ? rank + 1 : rank
          end
        end
        return 0.0 if rank == 0

        norm = Math.log(sentence_1.size) + Math.log(sentence_2.size)
        return rank * 1.0 if sentence_1.size + sentence_2.size == 2
        rank / norm
      end

      private def select_sentences(text : String, max_num_sentences = 5) : Array(String)
        return [""] unless text.size > 0 && max_num_sentences > 0
        matrix = create_matrix(text)
        ranks = power_method(matrix, @epsilon)
        ranks_array = ranks.to_a
        sentences = text.tokenize(Tokenizer::Sentence)
        ranked = sentences.zip(ranks_array).sort_by { |sentence_and_rating| -sentence_and_rating[1] }
        # Select top sentences and sort by original position
        ranked[..max_num_sentences - 1].sort_by { |sentence_and_rating| sentences.index(sentence_and_rating[0]) || 0 }.map { |sentence_and_rating| sentence_and_rating[0] }
      end
    end
  end
end
