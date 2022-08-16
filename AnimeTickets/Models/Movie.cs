using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using AnimeTickets.Models.Base;

namespace AnimeTickets.Models;

public class Movie : IEntityBase
{
    [Key]
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public double Price { get; set; }
    public string ImageURL { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public MovieCategory MovieCategory { get; set; }

    //Relationship
    public List<Character_Movie> Character_Movies { get; set; }
    //Cinema relationship
    public int CinemaId { get; set; }  
    [ForeignKey("CinemaId")]
    public Cinema Cinema { get; set; }
    
    //Producer relationship
    public int ProducerId { get; set; }  
    [ForeignKey("ProducerId")]
    public Producer Producer { get; set; }
}