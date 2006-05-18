class NoteVote < Vote
  USEFUL = 1
  NOT_USEFUL = 2
  SPAM = 3
  
  def vote_to_s
    case vote_type
      when USEFUL then return 'useful'
      when NOT_USEFUL then return 'not useful'
      when SPAM then return 'spam'
    end
    
    return 'unknown'
  end
end
