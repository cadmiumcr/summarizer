require "./spec_helper"

summary_length = {
  5 => "We must, therefore, know both the cause and effect, and the relation between them. We only feel the event, namely, the existence of an idea, consequent to a command of the will: But the manner, in which this operation is performed, the power by which it is produced, is entirely beyond our comprehension. Do you find anything in it like this creative power, by which it raises from nothing a new idea, and with a kind of Fiat, imitates the omnipotence of its Maker, if I may be allowed so to speak, who called forth into existence all the various scenes of nature? But to hasten to a conclusion of this argument, which is already drawn out to too great a length: We have sought in vain for an idea of power or necessary connexion in all the sources from which we could suppose it to be derived. But when one particular species of event has always, in all instances, been conjoined with another, we make no longer any scruple of foretelling one upon the appearance of the other, and of employing that reasoning, which can alone assure us of any matter of fact or existence.",
  2 => "We must, therefore, know both the cause and effect, and the relation between them. Do you find anything in it like this creative power, by which it raises from nothing a new idea, and with a kind of Fiat, imitates the omnipotence of its Maker, if I may be allowed so to speak, who called forth into existence all the various scenes of nature?",
  0 => "",
}

describe Cadmium::Summarizer::TextRank do
  subject = Cadmium::Summarizer::TextRank.new

  it "should summarize a long text to default number (5) sentences" do
    subject.summarize(hume_text, 5).should eq(summary_length[5])
  end

  it "should summarize a long text according to the input max_num_sentences" do
    subject.summarize(hume_text, 2).should eq(summary_length[2])
  end

  it "should return an empty string if max_num_sentences is 0" do
    subject.summarize(hume_text, 0).should eq(summary_length[0])
  end

  it "should summarize text via String#summarize" do
    hume_text.summarize(Cadmium::Summarizer::TextRank).should eq(summary_length[5])
  end
end
