using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace AnimeTickets.Models;

public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Character_Movie>().HasKey(am => new
        {
            am.CharacterId,
            am.MovieId
        });


        modelBuilder.Entity<Character_Movie>().HasOne(m => m.Movie).WithMany(am => am.Character_Movies)
            .HasForeignKey(m => m.MovieId);

        modelBuilder.Entity<Character_Movie>().HasOne(m => m.Character).WithMany(am => am.Character_Movies)
            .HasForeignKey(m => m.CharacterId);
        base.OnModelCreating(modelBuilder);
    }

    public DbSet<Character> Characters { get; set; }
    public DbSet<Movie> Movies { get; set; }
    public DbSet<Character_Movie> Character_Movies { get; set; }
    public DbSet<Cinema> Cinema { get; set; }
    public DbSet<Producer> Producers { get; set; }
    
    public  DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<ShoppingCartItem> ShoppingCartItems { get; set; }



}