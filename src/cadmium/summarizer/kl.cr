require "./summarizer"

module Cadmium
  module Summarizer
    # Method that greedily adds sentences to a summary so long as it decreases the
    # KL Divergence.
    # Step 1 : Puts all sentences of the documents in an array.
    # Step 2 : Calculate the frequency ( = normalized ratio) of each term in the document. (words_frequency)
    # Step 3 : Takes one sentence from the array (all_sentences_array) at a time.
    # Step 4 : Converts temporary summary (final_summary) to a word list array
    # Step 5 : Calculates the joint frequency between the words of the considered sentence and the words of the final_summary.
    # Step 6 : Calculates the kl divergence between the joint frequency and the words_frequency and put it into a hash of (calculated_kld => considered_sentence). This hash is the kl_summary or kls
    # Step 7 : Select the best sentence from the kl_summary, remove it from all_sentences_array and add it to final_summary hash (rating => sentence)
    # Step 8 : Rate this sentence (-1 * final_summary.size) and update its rating in the final_summary hash.

    # Source: http://www.aclweb.org/anthology/N09-1041
    class KL < AbstractSummarizer
      private def joint_frequency(terms_in_sentence : Array(String), terms_in_summary : Array(String)) : Hash(String, Float64)
        total_number_of_terms = terms_in_sentence.size + terms_in_summary.size
        terms_frequencies_in_sentence = terms_frequencies(terms_in_sentence).transform_values { |frequency| frequency.to_f }
        terms_frequencies_in_summary = terms_frequencies(terms_in_summary).transform_values { |frequency| frequency.to_f }
        joint = terms_frequencies_in_sentence

        terms_frequencies_in_summary.keys.each do |term|
          joint[term] = joint.keys.includes?(term) ? joint[term] + terms_frequencies_in_summary[term] : terms_frequencies_in_summary[term]
        end

        joint.keys.each do |term|
          joint[term] /= total_number_of_terms
        end

        joint
      end

      private def kl_divergence(final_summary_frequencies : Hash(String, Float64), text_normalized_frequencies : Hash(String, Float64)) : Float64
        kld = 0.0
        final_summary_frequencies.keys.each do |term|
          kld += text_normalized_frequencies[term] * Math.log(text_normalized_frequencies[term] / final_summary_frequencies[term]) if text_normalized_frequencies.keys.includes?(term) && text_normalized_frequencies[term] != 0
        end
        kld
      end

      private def select_sentences(text : String, max_num_sentences : Int, normalized_terms_ratio : Hash(String, Float64)) : Array(String)
        final_summary = Hash(String, Float64).new
        all_sentences_significant_terms = Sentence.sentences(text).each_with_object({} of String => Array(String)) { |sentence, significant_terms| significant_terms[sentence] = significant_terms(sentence) } # Step 1
        terms_frequency = normalized_terms_ratio(text)                                                                                                                                                         # Step 2

        all_sentences_significant_terms.keys.each do |selected_sentence| # Step 3
          summary_as_word_list = Array(String).new
          final_summary.keys.each { |sentence| summary_as_word_list += all_terms(sentence) } # Step 4
          kl_summary = Hash(String, Float64).new

          all_sentences_significant_terms.values.each do |significant_terms|
            joint_frequency = joint_frequency(significant_terms, summary_as_word_list)      # Step 5
            kl_summary[selected_sentence] = kl_divergence(joint_frequency, terms_frequency) # Step 6
          end

          best_sentence = kl_summary.min_by { |_, kl| kl }.first # Step 7
          all_sentences_significant_terms.reject!(best_sentence)
          final_summary[best_sentence] = -1.0 * final_summary.size # Step 8
        end

        selected_sentences = [] of String
        final_summary = final_summary.to_a.sort_by { |_, rating| -rating }.first(max_num_sentences)

        final_summary.each do
          selected_sentences << final_summary.first[0]
        end

        selected_sentences
      end
    end
  end
end
