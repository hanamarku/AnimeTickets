using AnimeTickets.Models.Base;
using System.ComponentModel.DataAnnotations;

namespace AnimeTickets.Models;

public class Producer : IEntityBase
{
    [Key]
    public int Id { get; set; }

    [Display(Name = "Profile Picture")]
    [Required(ErrorMessage = "Profile picture is required")]
    public string ProfilePictureURL { get; set; }

    [Display(Name = "Full Name")]
    [Required(ErrorMessage = "Full name is required")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Full name must be between 3 and 50 chars")]
    public string FullName { get; set; }

    [Display(Name = "Biography")]
    [Required(ErrorMessage = "Decsription is required")]
    public string Bio { get; set; }

    //Relationship 
    public List<Movie>? Movies { get; set; }
}