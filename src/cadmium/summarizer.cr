require "./summarizer/*"

module Cadmium
  module DocumentExtension
    property summary : String?

    def summarize(summarizer = Cadmium::Summarizer::Luhn, *args, **kwargs)
      summarizer = summarizer.new(*args, **kwargs)
      self.summary = summarizer.summarize(self.verbatim)
    end
  end

  # class Document
  #   include DocumentExtension
  # end
end
