using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KoreanTaxi.Migrations
{
    /// <inheritdoc />
    public partial class customernamenotnullable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "customername",
                table: "companycustomerphonenumbers",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_companycustomerphonenumbers_customername",
                table: "companycustomerphonenumbers",
                column: "customername");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_companycustomerphonenumbers_customername",
                table: "companycustomerphonenumbers");

            migrationBuilder.AlterColumn<string>(
                name: "customername",
                table: "companycustomerphonenumbers",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);
        }
    }
}
