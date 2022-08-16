using AnimeTickets.Models;
using AnimeTickets.Models.Base;

namespace AnimeTickets.Data.Services;

public interface IMovieService : IEntityaBaseRepository<Movie>
{
    Task<Movie> GetMovieByIdAsync(int id);
    Task<NewMovieDropdownsVM> GetMovieDropdownsValues();
    Task AddNewMovieAsync(NewMovieVM data);
    Task UpdateMovieAsync(NewMovieVM data);
}