using AnimeTickets.Data.Base;
using AnimeTickets.Models;
using AnimeTickets.Models.Base;
using AnimeTickets.Models.Services;

namespace AnimeTickets.Data.Services;

public class ProducersService: EntityBaseRepository<Producer> , IProducersService
{
    public ProducersService(AppDbContext context) : base(context) { }
    
}