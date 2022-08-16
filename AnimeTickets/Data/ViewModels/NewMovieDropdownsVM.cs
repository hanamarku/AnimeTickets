using AnimeTickets.Controllers;

namespace AnimeTickets.Models;

public class NewMovieDropdownsVM
{
    public NewMovieDropdownsVM()
    {
        Producers = new List<Producer>();
        Cinemas = new List<Cinema>();
        Characters = new List<Character>();
    }
    public List<Producer> Producers { get; set; }
    public List<Cinema> Cinemas { get; set; }
    public List<Character> Characters { get; set; }
}