namespace AnimeTickets.Models;

public class Character_Movie
{
    public int MovieId { get; set; }
    public Movie Movie { get; set; }
    public int CharacterId { get; set; }
    public Character Character { get; set; }
}