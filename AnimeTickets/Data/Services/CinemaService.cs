using AnimeTickets.Data.Base;
using AnimeTickets.Models;
using AnimeTickets.Models.Base;
using AnimeTickets.Models.Services;

namespace AnimeTickets.Data.Services;

public class CinemaService : EntityBaseRepository<Cinema>, ICinemasService
{
    public CinemaService(AppDbContext context) : base(context)
    {
    }
}