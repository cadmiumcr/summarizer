require "./spec_helper"

summary_length = {
  5 => "The great advantage of the mathematical sciences above the moral consists in this, that the ideas of the former, being sensible, are always clear and determinate, the smallest distinction between them is immediately perceptible, and the same terms are still expressive of the same ideas, without ambiguity or variation. An oval is never mistaken for a circle, nor an hyperbola for an ellipsis. The isosceles and scalenum are distinguished by boundaries more exact than vice and virtue, right and wrong. If any term be defined in geometry, the mind readily, of itself, substitutes, on all occasions, the definition for the term defined: Or even when no definition is employed, the object itself may be presented to the senses, and by that means be steadily and clearly apprehended. But the finer sentiments of the mind, the operations of the understanding, the various agitations of the passions, though really in themselves distinct, easily escape us, when surveyed by reflection; nor is it in our power to recal the original object, as often as we have occasion to contemplate it. Ambiguity, by this means, is gradually introduced into our reasonings: Similar objects are readily taken to be the same: And the conclusion becomes at last very wide of the premises.",
  2 => "The great advantage of the mathematical sciences above the moral consists in this, that the ideas of the former, being sensible, are always clear and determinate, the smallest distinction between them is immediately perceptible, and the same terms are still expressive of the same ideas, without ambiguity or variation. An oval is never mistaken for a circle, nor an hyperbola for an ellipsis. The isosceles and scalenum are distinguished by boundaries more exact than vice and virtue, right and wrong.",
  0 => "",
}

describe Cadmium::Summarizer::Luhn do
  subject = Cadmium::Summarizer::Luhn.new

  it "should summarize a long text to default number (5) sentences" do
    subject.summarize(hume_text).should eq(summary_length[5])
  end

  it "should summarize a long text according to the input max_num_sentences" do
    subject.summarize(hume_text, 2).should eq(summary_length[2])
  end

  it "should return an empty string if max_num_sentences is 0" do
    subject.summarize(hume_text, 0).should eq(summary_length[0])
  end

  it "should summarize text via String#summarize" do
    hume_text.summarize(Cadmium::Summarizer::Luhn).should eq(summary_length[5])
  end
end

describe Cadmium::Document do
  subject = Cadmium::Document.new(hume_text)

  it "should summarize text via Document#summarize" do
    subject.summarize.should eq(summary_length[5])
  end
end
