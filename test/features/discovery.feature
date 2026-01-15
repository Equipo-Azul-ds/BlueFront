@optionalTypeArgs
Feature: Descubrimiento de Kahoots

  Background:
    Given la API de descubrimiento está disponible

  Scenario: Buscar Kahoots por palabra clave
    When ingreso la palabra "Matemáticas" en el buscador
    And presiono el botón de búsqueda
    Then debería ver una lista de Kahoots relacionados con "Matemáticas"

  Scenario: Cargar categorías de exploración al inicio
    When abro la pantalla de descubrimiento
    Then debería ver la categoría "Historia"
    And debería ver la categoría "Arte"