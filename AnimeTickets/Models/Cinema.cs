using System.ComponentModel.DataAnnotations;
using AnimeTickets.Models.Base;

namespace AnimeTickets.Models;

public class Cinema : IEntityBase
{
    [Key]
    public int Id { get; set; }

    [Display(Name = "Logo")]
    public string Logo { get; set; }

    [Display(Name = "Name")]
    public string Name { get; set; }

    [Display(Name = "Description")]
    public string Description { get; set; }

    //Relationship
    public List<Movie>? Movies { get; set; }
}