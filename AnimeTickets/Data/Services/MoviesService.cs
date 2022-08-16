using AnimeTickets.Data.Base;
using AnimeTickets.Models;
using Microsoft.EntityFrameworkCore;

namespace AnimeTickets.Data.Services;

public class MoviesService : EntityBaseRepository<Movie>, IMovieService
{
    private readonly AppDbContext _context;
    public MoviesService(AppDbContext context) : base(context)
    {
        _context = context;
    }

    public async Task<Movie> GetMovieByIdAsync(int id)
    {
        var movieDet = _context.Movies
            .Include(c => c.Cinema)
            .Include(p => p.Producer)
            .Include(cm => cm.Character_Movies).ThenInclude(a => a.Character)
            .FirstOrDefault(n => n.Id == id);
        return movieDet;
    }

    public async Task<NewMovieDropdownsVM> GetMovieDropdownsValues()
    {
        var result = new NewMovieDropdownsVM()
        {
            Characters = await _context.Characters.OrderBy(n => n.FullName).ToListAsync(),
            Cinemas = await _context.Cinema.OrderBy(n => n.Name).ToListAsync(),
            Producers = await _context.Producers.OrderBy(n => n.FullName).ToListAsync()

        };
        return result;
    }

    public async Task AddNewMovieAsync(NewMovieVM data)
    {
        var newMovie = new Movie()
        {
            Name = data.Name,
            Description = data.Description,
            Price = data.Price,
            ImageURL = data.ImageURL,
            CinemaId = data.CinemaId,
            StartDate = data.StartDate,
            EndDate = data.EndDate,
            MovieCategory = data.MovieCategory,
            ProducerId = data.ProducerId
        };
        await _context.Movies.AddAsync(newMovie);
        await _context.SaveChangesAsync();

        foreach (var characterId in data.CharacterIds)
        {
            var newCharacterMovie = new Character_Movie()
            {
                MovieId = newMovie.Id,
                CharacterId = characterId
            };
            await _context.Character_Movies.AddAsync(newCharacterMovie);
        }
        await _context.SaveChangesAsync();
    }

    public async Task UpdateMovieAsync(NewMovieVM data)
    {
        var dbMovie = await _context.Movies.FirstOrDefaultAsync(n => n.Id == data.Id);

        if (dbMovie != null)
        {
            dbMovie.Name = data.Name;
            dbMovie.Description = data.Description;
            dbMovie.Price = data.Price;
            dbMovie.ImageURL = data.ImageURL;
            dbMovie.CinemaId = data.CinemaId;
            dbMovie.StartDate = data.StartDate;
            dbMovie.EndDate = data.EndDate;
            dbMovie.MovieCategory = data.MovieCategory;
            dbMovie.ProducerId = data.ProducerId;

            await _context.SaveChangesAsync();
        }

        //remove existing characters
        var existingCharacters = _context.Character_Movies.Where(n => n.MovieId == data.Id).ToList();
        _context.Character_Movies.RemoveRange(existingCharacters);
        await _context.SaveChangesAsync();


        foreach (var characterId in data.CharacterIds)
        {
            var newCharacterMovie = new Character_Movie()
            {
                MovieId = data.Id,
                CharacterId = characterId
            };
            await _context.Character_Movies.AddAsync(newCharacterMovie);
        }
        await _context.SaveChangesAsync();
    }
}