module StubTime
  def self.included(base)
    base.class_eval do
      let!(:now)     { Time.now }
      let!(:now_utc) { Time.now.utc }

      before :each do
        allow(Time).to receive(:now).and_return(now)
        allow(now).to receive(:utc).and_return(now_utc)
      end
    end
  end
end
